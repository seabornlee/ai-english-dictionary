const mongoose = require('mongoose');

const avoidWordSchema = new mongoose.Schema({
  word: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  avoidWords: [{
    type: String,
    required: true
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update the updatedAt timestamp before saving
avoidWordSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('AvoidWord', avoidWordSchema); 