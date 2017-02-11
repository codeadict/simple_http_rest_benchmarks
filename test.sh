WRK_CMD=""

set -xe

envs=(python2 python3 pypy)

# If already in a python venv, get out. 
deactivate 2> /dev/null || true

# Clean up any existing virutal envs
find . -name venv | xargs rm -rf
find . -name \*.log | xargs rm -rf

# For each python lib to be tested
for lib in $(find python -type d -mindepth 1 -maxdepth 1); do

    # `cd` in to each python lib directory
    pushd $lib
    for py in ${envs[@]}; do
        # start a log file
        log="$lib_$py.log"
        echo -n > $log

        # stash the Python version used
        py_ver=$($py --version 2>&1)
        echo "|$|PYTHON_VERSION|$py_ver" >> $log

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
        cmd="wrk -d 10s -c 300 -t 8 --latency http://localhost:8005 | tee -a $log"
        echo "|$|WRK:gunicorn|$cmd"
        $cmd
        kill %1
    done
    popd
done
