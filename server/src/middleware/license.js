// @ts-check
const jwt = require('jsonwebtoken');

if (process.env.NODE_ENV === 'production' && !process.env.LICENSE_SECRET) {
  throw new Error('LICENSE_SECRET environment variable is required in production');
}

const LICENSE_SECRET =
  process.env.LICENSE_SECRET ||
  (process.env.NODE_ENV === 'test' ? 'test-license-secret-do-not-use-in-production' : null);

if (!LICENSE_SECRET) {
  throw new Error('LICENSE_SECRET environment variable must be set');
}

/**
 * @typedef {Object} LicensePayload
 * @property {string} type
 * @property {string} licenseId
 * @property {string} deviceId
 * @property {string} bundleId
 * @property {number} [exp]
 */

/**
 * License verification middleware
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
const license = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'License required', code: 'LICENSE_REQUIRED' });
    }

    const token = authHeader.replace('Bearer ', '');
    const decoded = /** @type {LicensePayload} */ (jwt.verify(token, LICENSE_SECRET));

    if (decoded.type !== 'license') {
      return res.status(401).json({ error: 'Invalid token type', code: 'INVALID_TOKEN_TYPE' });
    }

    // Check expiration
    if (decoded.exp && Date.now() > decoded.exp * 1000) {
      return res.status(401).json({ error: 'License expired', code: 'LICENSE_EXPIRED' });
    }

    // @ts-ignore - extending request with license
    req.license = decoded;
    // @ts-ignore - extending request with licenseToken
    req.licenseToken = token;
    next();
  } catch (error) {
    const err = /** @type {Error} */ (error);
    if (err.name === 'JsonWebTokenError') {
      return res
        .status(401)
        .json({ error: 'Invalid license token', code: 'INVALID_LICENSE_TOKEN' });
    }
    if (err.name === 'TokenExpiredError') {
      return res
        .status(401)
        .json({ error: 'License token expired', code: 'LICENSE_TOKEN_EXPIRED' });
    }
    res.status(500).json({ error: 'License verification error', code: 'LICENSE_ERROR' });
  }
};

/**
 * @typedef {Object} LicenseData
 * @property {string} licenseId
 * @property {string} deviceId
 * @property {string} bundleId
 */

/**
 * Generate license token
 * @param {LicenseData} licenseData
 * @returns {string}
 */
const generateLicenseToken = licenseData => {
  return jwt.sign(
    {
      type: 'license',
      licenseId: licenseData.licenseId,
      deviceId: licenseData.deviceId,
      bundleId: licenseData.bundleId,
    },
    LICENSE_SECRET,
    { expiresIn: '365d' }
  );
};

module.exports = { license, generateLicenseToken, LICENSE_SECRET };
