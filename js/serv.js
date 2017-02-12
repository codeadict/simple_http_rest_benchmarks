var express = require('express');
var app = express();
var fs = require("fs");

app.get('/', function (req, res) {
    res.end('Hello, world!')
})

var server = app.listen(8005, function () {
      let host = server.address().address
      let port = server.address().port
      console.log("App listening @ http://%s:%s", host, port)
})
