require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');
const dictionaryRoutes = require('./routes/dictionary');

const app = express();
const PORT = process.env.PORT || 3000;
process.env.MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ai-dictionary';

// Initialize database connection
const initializeDatabase = async () => {
  try {
    const uri =
      process.env.NODE_ENV === 'test' ? process.env.MONGODB_URI + '_test' : process.env.MONGODB_URI;

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
    console.error('Database initialization error:', error.message);
    console.error('Full error:', error);
    if (error.code) console.error('Error code:', error.code);
    if (error.codeName) console.error('Error codeName:', error.codeName);
    console.log('App will continue without database functionality');
  }
};

initializeDatabase();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/dictionary', dictionaryRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  const mongoState = mongoose.connection.readyState;
  const mongoStatus = mongoState === 1 ? 'connected' : 'disconnected';
  res.status(200).json({ status: 'ok', mongo: mongoStatus, state: mongoState });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
  });
});

// Create and start server
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = {
  app,
  server,
};
