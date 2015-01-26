var http = require('http');

var server = http.createServer(function (request, response) {
  response.writeHead(200, {"Content-Type": "text/plain"});
  response.end("WarpSpeed say hello, from Node!\n");
});

// passenger will auto-set listen port
server.listen(3000);
