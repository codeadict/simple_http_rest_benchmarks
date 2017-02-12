#!/usr/bin/env bash

set -xe

# If already in a python venv, get out. 
deactivate 2> /dev/null || true

log="$(pwd)/runs.log"
echo -n > $log

# System stats.
echo "|$|processor|$(grep "model name" /proc/cpuinfo | head -n 1)" >> $log
echo "|$|processor_count|$(grep processor /proc/cpuinfo | wc -l)" >> $log
echo "|$|memory|$(fee -h | grep mem)" >> $log

# Kill zombies that could be taking up port 8005.
zombies=$(ps aux | grep python_falcon | grep gunicorn | grep -v grep | awk '{print $2}' | xargs)
if [ ! -z "$zombies" ]; then
    kill -9 $zombies
fi
zombies=$(ps aux | grep serv.py | grep -v grep | awk '{print $2}' | xargs)
if [ ! -z "$zombies" ]; then
    kill -9 $zombies
fi
zombies=$(ps aux | grep "/exe/main" | grep -v grep | awk '{print $2}' | xargs)
if [ ! -z "$zombies" ]; then
    kill -9 $zombies
fi
zombies=$(ps aux | grep serv.js | grep -v grep | awk '{print $2}' | xargs)
if [ ! -z "$zombies" ]; then
    kill -9 $zombies
fi

#
# Python: Falcon
#

envs=(python2 pypy python3)
pushd python_falcon
rm -rf venv
for py in ${envs[@]}; do
    # initialize a new venv
    virtualenv -p "$(which $py)" venv
    source venv/bin/activate
    pip install --quiet -r requirements.txt
    if [[ "$py" == "python2" || "$py" == "pypy" ]]; then
        pip install futures
    fi

    # start a gunicorn server
    gunicorn \
        --threads 4 \
        --bind 0.0.0.0:8005 \
        serv:app &
    sleep 3

    # get some `wrk` load testing stats
    # stash the Python version used
    py_ver=$($py --version 2>&1)
    echo "|$|WRK|$py:falcon|$WRK_CMD" >> $log
    wrk -c 400 -t 8 -d 10s --latency http://localhost:8005 2>&1 | tee -a $log
    zombies=$(ps aux | grep python_falcon | grep gunicorn | grep -v grep | awk '{print $2}' | xargs)
    if [ ! -z "$zombies" ]; then
        kill -9 $zombies
    fi
done
popd

#
# Python: aiohttp
#

envs=(python3)
pushd python_aiohttp
rm -rf venv
for py in ${envs[@]}; do
    # initialize a new venv
    virtualenv -p "$(which $py)" venv
    source venv/bin/activate
    pip install --quiet -r requirements.txt

    python serv.py &
    sleep 3

    # get some `wrk` load testing stats
    # stash the Python version used
    py_ver=$($py --version 2>&1)
    echo "|$|WRK|$py:aiohttp|$WRK_CMD" >> $log
    wrk -c 400 -t 8 -d 10s --latency http://localhost:8005 2>&1 | tee -a $log
    zombies=$(ps aux | grep serv.py | grep -v grep | awk '{print $2}' | xargs)
    if [ ! -z "$zombies" ]; then
        kill -9 $zombies
    fi
done
popd

#
# Go
# 

# Need to have Go installed
pushd go
export GOPATH=`pwd`
go run src/serv/main.go &
sleep 3
echo "|$|WRK|go:$(go version)|$WRK_CMD" >> $log
wrk -c 400 -t 8 -d 10s --latency http://localhost:8005 2>&1 | tee -a $log
zombies=$(ps aux | grep "/exe/main" | grep -v grep | awk '{print $2}' | xargs)
if [ ! -z "$zombies" ]; then
    kill -9 $zombies
fi
popd

#
# Node
#

# Need to have node and npm installed
pushd js
rm -rf node_modules npm-debug.log
npm install
node serv.js &
sleep 3
echo "|$|WRK|node:$(node --version)|$WRK_CMD" >> $log
wrk -c 400 -t 8 -d 10s --latency http://localhost:8005 2>&1 | tee -a $log
zombies=$(ps aux | grep serv.js | grep -v grep | awk '{print $2}' | xargs)
if [ ! -z "$zombies" ]; then
    kill -9 $zombies
fi
popd
