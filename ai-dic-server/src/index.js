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

    await mongoose.connect(uri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

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
    console.error('Database initialization error:', error);
    throw error;
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
  res.status(200).json({ status: 'ok' });
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
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = {
  app,
  server,
};
