
if ((process.argv.length) < 5)
{
	console.log(`Incorrect commandline arguments: ${process.argv}. Will exit.`);
	process.exit(1);
}

var ip_address=process.argv[2];
var port=process.argv[3];

const PythonShell = require('python-shell').PythonShell;

var options = {
  mode: 'text',
  pythonPath: '/usr/bin/python3',
  pythonOptions: ['-u'],
  scriptPath: process.argv[4],
  args: ['value1', 'value2', 'value3']
};
let pytshell = new PythonShell('temperature.py', options); 
let temperature="N/A";
let humidity="N/A";
let splitted = []
pytshell.on('message', function (message) {
  splitted=message.split(":");
  temperature=splitted[0];
  humidity=splitted[1];
});

var http = require('http');
var express = require('express');

var app = express();

app.use(express['static'](__dirname ));

// Express route for incoming requests for temperature
app.get('/sensors/temperature', function(req, res) {
  res.status(200).send(temperature);
}); 

// Express route for incoming requests for humidity
app.get('/sensors/humidity', function(req, res) {
  res.status(200).send(humidity);
}); 

// Express route for any other unrecognised incoming requests
app.get('*', function(req, res) {
  res.status(404).send('Unrecognised API call');
});

// Express route to handle errors
app.use(function(err, req, res, next) {
  if (req.xhr) {
    res.status(500).send('Oops, Something went wrong!');
  } else {
    next(err);
  }
});

app.listen(port,ip_address);

console.log(`Server running at ${ip_address}:${port}/`);
