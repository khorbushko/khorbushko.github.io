const net = require('net');

const server = net.createServer((socket) => {
  socket.on('data', (data) => {
    console.log(data.toString());
  });
}).on('error', (err) => {
  console.error(err);
});

// Open server on port 1234
server.listen(1234, () => {
  console.log('opened server on', server.address().port);
});
