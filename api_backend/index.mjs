// index.mjs
import express from 'express';
import serverless from 'serverless-http';
import cors from 'cors';

const app = express();

// Enable CORS for all routes with specific options
const corsOptions = {
  origin: '*',
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
  preflightContinue: false,
  optionsSuccessStatus: 204,
  allowedHeaders: ['Content-Type', 'Accept', 'Authorization', 'X-Amz-Date', 'X-Api-Key', 'X-Amz-Security-Token'],
  credentials: true
};

app.use(cors(corsOptions));

// Additional headers for OPTIONS requests
app.options('*', cors(corsOptions));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));


// getHello
app.get('/hello', (req, res) => {
  res.json({
    message: `I have received your GET for /hello and now all you have to do is add code here to process it`,
    method: 'GET',
    resource: '/hello'
  });
});

// Handle 404
app.use((req, res) => {
  res.status(404).json({ message: 'Route NOT found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: 'Internal server error' });
});

const handler = serverless(app);
export { handler };