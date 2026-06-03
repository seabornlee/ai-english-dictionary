const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      minlength: 6,
    },
    authProvider: {
      type: String,
      enum: ['local', 'firebase'],
      default: 'local',
    },
    firebaseUid: {
      type: String,
      sparse: true,
      unique: true,
    },
    displayName: {
      type: String,
    },
    favorites: [
      {
        term: String,
        definition: String,
        pronunciation: String,
        partOfSpeech: String,
        exampleSentences: [String],
        timestamp: Date,
      },
    ],
    history: [
      {
        term: String,
        definition: String,
        pronunciation: String,
        partOfSpeech: String,
        exampleSentences: [String],
        timestamp: Date,
      },
    ],
    vocabulary: [
      {
        term: String,
        definition: String,
        pronunciation: String,
        partOfSpeech: String,
        exampleSentences: [String],
        timestamp: Date,
      },
    ],
    isVerified: {
      type: Boolean,
      default: false,
    },
    verificationToken: {
      type: String,
      default: null,
    },
    verificationTokenExpires: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Require password only for local auth
userSchema.pre('validate', function (next) {
  if (this.authProvider === 'local' && !this.password) {
    this.invalidate('password', 'Password is required for local auth');
  }
  next();
});

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Remove password from JSON output
userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.password;
  delete obj.verificationToken;
  delete obj.verificationTokenExpires;
  return obj;
};

// Generate verification token
userSchema.methods.generateVerificationToken = function () {
  const token = crypto.randomBytes(32).toString('hex');
  this.verificationToken = crypto.createHash('sha256').update(token).digest('hex');
  this.verificationTokenExpires = Date.now() + 24 * 60 * 60 * 1000; // 24 hours
  return token; // Return plain token (will be sent in email)
};

module.exports = mongoose.model('User', userSchema);
