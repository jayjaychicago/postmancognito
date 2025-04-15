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

// Path normalization middleware
app.use((req, res, next) => {
  // Strip environment prefix if present version JULIEN v2
  if (req.path.startsWith('/prod') || req.path.startsWith('/dev') || req.path.startsWith('/staging')) {
    console.log(`Normalizing path: ${req.path} -> ${req.path.replace(/^\/prod|\/dev|\/staging/, '')}`);
    req.url = req.url.replace(/^\/prod|\/dev|\/staging/, '');
  }
  
  // Log the full request to see structure
  console.log('headers', req.headers);
  console.log('req', req);

  const claims = req.requestContext.authorizer.lambda;
  // TODO Change and remove this once switched to a lambda authorizer
  
  if (claims) {
    // Create a simplified user object with the essential Cognito information
    req.user = {
      sub: claims.sub,
      username: claims.username,
      groups: claims['cognito:groups']
    };
  };
  
  next();
});

// getHello
app.get('/hello', (req, res) => {
  console.log(`Route matched: ${req.path} (Original URL: ${req.originalUrl})`);
  
  res.json({
    message: `I have received your GET for /hello and now all you have to do is add code here to process it`,
    method: 'GET',
    resource: '/hello',
    originalUrl: req.originalUrl,
    path: req.path,
    user: req.user || {
      sub: 'unknown',
      username: 'unknown',
      groups: []
    },
    body: req.body || {},
    query: req.query || {}
  });
});


// Catch-all route handler for unmatched paths
app.use((req, res) => {
  console.log(`No route matched: ${req.path} (Method: ${req.method})`);
  res.status(404).json({
    error: 'Not Found',
    message: `No handler defined for ${req.method} ${req.path}`,
    path: req.path,
    method: req.method
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