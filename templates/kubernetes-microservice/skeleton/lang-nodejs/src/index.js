const { SERVICE, createServer } = require('./server');

const port = Number.parseInt(process.env.PORT ?? '8080', 10);
const server = createServer();

server.listen(port, () => {
  console.log(`${SERVICE} listening on port ${port}`);
});

// A process started as PID 1 in a container gets no default signal handling.
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => server.close(() => process.exit(0)));
}
