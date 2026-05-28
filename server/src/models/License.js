const mongoose = require('mongoose');

const licenseSchema = new mongoose.Schema(
  {
    receiptHash: {
      type: String,
      required: true,
      unique: true,
    },
    bundleId: {
      type: String,
      required: true,
    },
    appVersion: {
      type: String,
      required: true,
    },
    originalPurchaseDate: {
      type: Date,
      required: true,
    },
    expirationDate: {
      type: Date,
      default: null,
    },
    deviceId: {
      type: String,
      required: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastValidationDate: {
      type: Date,
      default: Date.now,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Index for quick lookup
licenseSchema.index({ receiptHash: 1 });
licenseSchema.index({ deviceId: 1 });

module.exports = mongoose.model('License', licenseSchema);
