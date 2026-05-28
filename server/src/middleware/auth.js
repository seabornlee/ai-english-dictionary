// @ts-check
const jwt = require('jsonwebtoken');
const User = require('../models/User');

if (process.env.NODE_ENV === 'production' && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required in production');
}

const JWT_SECRET =
  process.env.JWT_SECRET ||
  (process.env.NODE_ENV === 'test' ? 'test-secret-do-not-use-in-production' : null);

if (!JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable must be set');
}

/**
 * Authentication middleware
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
const auth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Authentication required', code: 'AUTH_REQUIRED' });
    }

    const token = authHeader.replace('Bearer ', '');
    const decoded = /** @type {{userId: string}} */ (jwt.verify(token, JWT_SECRET));
    const user = await User.findById(decoded.userId);

    if (!user) {
      return res.status(401).json({ error: 'User not found', code: 'USER_NOT_FOUND' });
    }

    // @ts-ignore - extending request with user
    req.user = user;
    // @ts-ignore - extending request with token
    req.token = token;
    next();
  } catch (error) {
    const err = /** @type {Error} */ (error);
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token', code: 'INVALID_TOKEN' });
    }
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired', code: 'TOKEN_EXPIRED' });
    }
    res.status(500).json({ error: 'Authentication error', code: 'AUTH_ERROR' });
  }
};

/**
 * Generate JWT token
 * @param {string} userId
 * @returns {string}
 */
const generateToken = userId => {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '30d' });
};

module.exports = { auth, generateToken, JWT_SECRET };
