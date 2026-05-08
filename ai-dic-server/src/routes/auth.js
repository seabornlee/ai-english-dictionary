const express = require('express');
const User = require('../models/User');
const License = require('../models/License');
const { auth, generateToken } = require('../middleware/auth');
const { license, generateLicenseToken } = require('../middleware/license');
const { sendVerificationEmail } = require('../services/emailService');
const { validateReceiptWithApple, extractReceiptInfo } = require('../services/receiptValidator');
const crypto = require('crypto');

const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required', code: 'MISSING_FIELDS' });
    }

    if (password.length < 6) {
      return res
        .status(400)
        .json({ error: 'Password must be at least 6 characters', code: 'PASSWORD_TOO_SHORT' });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered', code: 'EMAIL_EXISTS' });
    }

    const user = new User({ email: email.toLowerCase(), password });
    await user.save();

    // Generate verification token
    const verificationToken = user.generateVerificationToken();
    await user.save();

    // Send verification email (don't block registration if email fails)
    try {
      await sendVerificationEmail(user.email, verificationToken);
    } catch (emailError) {
      console.error('Failed to send verification email:', emailError);
    }

    const token = generateToken(user._id);

    res
      .status(201)
      .json({
        token,
        user: user.toJSON(),
        message: 'Registration successful. Please verify your email.',
      });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Registration failed', code: 'REGISTER_ERROR' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required', code: 'MISSING_FIELDS' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials', code: 'INVALID_CREDENTIALS' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials', code: 'INVALID_CREDENTIALS' });
    }

    // Check if email is verified
    if (!user.isVerified) {
      return res
        .status(403)
        .json({ error: 'Please verify your email before logging in', code: 'EMAIL_NOT_VERIFIED' });
    }

    const token = generateToken(user._id);

    res.json({ token, user: user.toJSON() });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed', code: 'LOGIN_ERROR' });
  }
});

// Logout (client-side token removal, but we can track if needed)
router.post('/logout', auth, async (req, res) => {
  // For JWT, logout is handled client-side by removing the token
  // Server can optionally maintain a token blacklist
  res.json({ success: true, message: 'Logged out successfully' });
});

// Get current user
router.get('/me', auth, async (req, res) => {
  res.json({ user: req.user.toJSON() });
});

// Send verification email
router.post('/send-verification', auth, async (req, res) => {
  try {
    if (req.user.isVerified) {
      return res.status(400).json({ error: 'Email already verified', code: 'ALREADY_VERIFIED' });
    }

    const token = req.user.generateVerificationToken();
    await req.user.save();

    const sent = await sendVerificationEmail(req.user.email, token);
    if (!sent) {
      return res
        .status(500)
        .json({ error: 'Failed to send verification email', code: 'SEND_ERROR' });
    }

    res.json({ success: true, message: 'Verification email sent' });
  } catch (error) {
    console.error('Send verification error:', error);
    res
      .status(500)
      .json({ error: 'Failed to send verification email', code: 'SEND_VERIFICATION_ERROR' });
  }
});

// Verify email with token
router.get('/verify-email/:token', async (req, res) => {
  try {
    const hashedToken = crypto.createHash('sha256').update(req.params.token).digest('hex');

    const user = await User.findOne({
      verificationToken: hashedToken,
      verificationTokenExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ error: 'Invalid or expired token', code: 'INVALID_TOKEN' });
    }

    user.isVerified = true;
    user.verificationToken = null;
    user.verificationTokenExpires = null;
    await user.save();

    res.json({ success: true, message: 'Email verified successfully' });
  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).json({ error: 'Verification failed', code: 'VERIFY_ERROR' });
  }
});

// Activate license from App Store receipt
router.post('/activate', async (req, res) => {
  try {
    const { receipt, deviceId, bundleId, appVersion } = req.body;

    if (!receipt || !deviceId || !bundleId) {
      return res
        .status(400)
        .json({ error: 'Receipt, deviceId, and bundleId required', code: 'MISSING_FIELDS' });
    }

    // Hash receipt to prevent storing raw data
    const receiptHash = crypto.createHash('sha256').update(receipt).digest('hex');

    // Check if license already exists (only if MongoDB is connected)
    let existingLicense = null;
    try {
      existingLicense = await License.findOne({ receiptHash });
    } catch (_dbError) {
      console.log('MongoDB not connected, skipping license lookup');
    }

    if (existingLicense) {
      // Update last validation date and return existing license
      existingLicense.lastValidationDate = new Date();
      existingLicense.isActive = true;
      await existingLicense.save();

      const token = generateLicenseToken({
        licenseId: existingLicense._id,
        deviceId: existingLicense.deviceId,
        bundleId: existingLicense.bundleId,
      });

      return res.json({
        success: true,
        token,
        licenseId: existingLicense._id,
        message: 'License reactivated',
      });
    }

    // Validate receipt with Apple
    let receiptInfo;
    try {
      const appleResponse = await validateReceiptWithApple(receipt);
      if (appleResponse.status !== 0) {
        return res.status(400).json({
          error: 'Invalid receipt',
          code: 'INVALID_RECEIPT',
          status: appleResponse.status,
        });
      }
      receiptInfo = extractReceiptInfo(appleResponse, bundleId);
    } catch (validationError) {
      // In development or when NODE_ENV not set, allow bypass with a test receipt
      const isDev = !process.env.NODE_ENV || process.env.NODE_ENV === 'development';
      if (isDev && receipt === 'development-test-receipt') {
        receiptInfo = {
          bundleId,
          appVersion: appVersion || '1.0.0',
          originalPurchaseDate: new Date(),
          expirationDate: null,
        };
      } else {
        console.error('Receipt validation error:', validationError);
        return res.status(400).json({
          error: 'Receipt validation failed',
          code: 'RECEIPT_VALIDATION_FAILED',
          details: validationError.message,
        });
      }
    }

    let licenseId;

    try {
      // Create new license in database
      const newLicense = new License({
        receiptHash,
        bundleId: receiptInfo.bundleId,
        appVersion: receiptInfo.appVersion,
        originalPurchaseDate: receiptInfo.originalPurchaseDate,
        expirationDate: receiptInfo.expirationDate,
        deviceId,
      });

      await newLicense.save();
      licenseId = newLicense._id;
    } catch (_dbError) {
      console.log('MongoDB not connected, generating token without database');
      licenseId = `no-db-${Date.now()}`;
    }

    const token = generateLicenseToken({
      licenseId: licenseId,
      deviceId: deviceId,
      bundleId: bundleId,
    });

    res.status(201).json({
      success: true,
      token,
      licenseId: licenseId,
      message: 'License activated successfully',
    });
  } catch (error) {
    console.error('License activation error:', error);
    res.status(500).json({ error: 'License activation failed', code: 'ACTIVATION_ERROR' });
  }
});

// Check license status
router.get('/license-status', license, async (req, res) => {
  try {
    const licenseData = await License.findById(req.license.licenseId);
    if (!licenseData) {
      return res.status(404).json({ error: 'License not found', code: 'LICENSE_NOT_FOUND' });
    }

    res.json({
      valid: licenseData.isActive,
      licenseId: licenseData._id,
      bundleId: licenseData.bundleId,
      appVersion: licenseData.appVersion,
      originalPurchaseDate: licenseData.originalPurchaseDate,
      expirationDate: licenseData.expirationDate,
      lastValidationDate: licenseData.lastValidationDate,
    });
  } catch (error) {
    console.error('License status error:', error);
    res.status(500).json({ error: 'Failed to get license status', code: 'STATUS_ERROR' });
  }
});

module.exports = router;
