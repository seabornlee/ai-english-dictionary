// @ts-check
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');
const crypto = require('crypto');
const dictionaryRoutes = require('./routes/dictionary');
const authRoutes = require('./routes/auth');
const syncRoutes = require('./routes/sync');
const chromeSyncRoutes = require('./routes/chrome-sync');
const { license } = require('./middleware/license');
const { auth } = require('./middleware/auth');
const { getAllFlags } = require('./config/featureFlags');
const { metricsMiddleware, getAll: getMetrics } = require('./lib/metrics');

const app = express();
/** @type {number} */
const PORT = Number(process.env.PORT) || 3000;
process.env.MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ai-dictionary';

/**
 * Initialize database connection
 * @returns {Promise<boolean>}
 */
const initializeDatabase = async () => {
  try {
    const baseUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/ai-dictionary';
    const uri = process.env.NODE_ENV === 'test' ? baseUri + '_test' : baseUri;

    /** @type {mongoose.ConnectOptions} */
    const options = {
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 45000,
    };

    // Enable TLS for MongoDB Atlas connections
    if (uri.includes('mongodb+srv')) {
      options.tls = true;
      options.tlsAllowInvalidCertificates = false;
    }

    await mongoose.connect(uri, options);

    // Create collections and indexes if needed
    const db = mongoose.connection.db;
    if (!db) {
      console.log('Database connection not ready');
      return false;
    }
    const collections = await db.listCollections().toArray();
    const collectionNames = collections.map(c => c.name);

    if (!collectionNames.includes('unknownwords')) {
      console.log('Creating unknownwords collection...');
      await db.createCollection('unknownwords');
    }

    // Create indexes
    const UnknownWord = require('./models/UnknownWord');
    await UnknownWord.createIndexes();

    console.log(`MongoDB connected successfully to ${uri}`);
    return true;
  } catch (error) {
    const err = /** @type {Error & {code?: string, codeName?: string}} */ (error);
    console.error('Database initialization error:', err.message);
    console.error('Full error:', err);
    if (err.code) console.error('Error code:', err.code);
    if (err.codeName) console.error('Error codeName:', err.codeName);
    console.log('App will continue without database functionality');
    return false;
  }
};

initializeDatabase();

// Middleware
// @ts-ignore - helmet types issue with ESM/CJS interop
app.use(helmet());
app.use(cors());
app.use(express.json());

// X-Request-ID middleware — generate UUID if not provided
app.use((req, res, next) => {
  const requestId = req.headers['x-request-id'] || crypto.randomUUID();
  req.headers['x-request-id'] = requestId;
  res.setHeader('X-Request-ID', requestId);
  next();
});

app.use(metricsMiddleware);

// Routes
app.use('/api/dictionary', license, dictionaryRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/sync', license, syncRoutes);
app.use('/api/sync/chrome', auth, chromeSyncRoutes);

// Health check endpoint
app.get('/health', (_req, res) => {
  const mongoState = mongoose.connection.readyState;
  const mongoStatus = mongoState === 1 ? 'connected' : 'disconnected';
  res.status(200).json({ status: 'ok', mongo: mongoStatus, state: mongoState });
});

// Feature flags endpoint
app.get('/api/features', (_req, res) => {
  res.json(getAllFlags());
});

// Metrics endpoint
app.get('/api/metrics', (_req, res) => {
  res.json(getMetrics());
});

/**
 * Error handler middleware
 * @param {Error} err
 * @param {express.Request} _req
 * @param {express.Response} res
 * @param {express.NextFunction} _next
 */
const errorHandler = (err, _req, res, _next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
  });
};
app.use(errorHandler);

// Create and start server
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = {
  app,
  server,
};
