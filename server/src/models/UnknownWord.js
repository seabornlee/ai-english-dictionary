const mongoose = require('mongoose');

const unknownWordSchema = new mongoose.Schema({
  word: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  unknownWords: [
    {
      type: String,
      required: true,
    },
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Update the updatedAt timestamp before saving
unknownWordSchema.pre('save', function (next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('UnknownWord', unknownWordSchema);
