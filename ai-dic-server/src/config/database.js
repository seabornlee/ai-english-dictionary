const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    // Use test database for tests
    const defaultURI = 'mongodb://localhost:27017/ai-dictionary';
    const mongoURI =
      process.env.NODE_ENV === 'test'
        ? (process.env.MONGODB_URI || defaultURI) + '_test'
        : process.env.MONGODB_URI || defaultURI;

    if (!mongoURI) {
      throw new Error('MongoDB URI is not defined in environment variables');
    }

    const conn = await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`Error connecting to MongoDB: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
