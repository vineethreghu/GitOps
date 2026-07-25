const express = require('express');
const app = express();
const port = 8080;

app.get('/', (req, res) => {
  res.json({
    message: 'GitOps Demo App',
    version: '1.0.0',
    hostname: process.env.HOSTNAME
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

const server = app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});

function shutdown() {
  console.log('SIGTERM received: shutting down gracefully');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });

  setTimeout(() => {
    console.error('Forcing shutdown after 10 seconds');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
