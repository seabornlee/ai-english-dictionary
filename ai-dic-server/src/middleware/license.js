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

const license = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'License required', code: 'LICENSE_REQUIRED' });
    }

    const token = authHeader.replace('Bearer ', '');
    const decoded = jwt.verify(token, LICENSE_SECRET);

    if (decoded.type !== 'license') {
      return res.status(401).json({ error: 'Invalid token type', code: 'INVALID_TOKEN_TYPE' });
    }

    // Check expiration
    if (decoded.exp && Date.now() > decoded.exp * 1000) {
      return res.status(401).json({ error: 'License expired', code: 'LICENSE_EXPIRED' });
    }

    req.license = decoded;
    req.licenseToken = token;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res
        .status(401)
        .json({ error: 'Invalid license token', code: 'INVALID_LICENSE_TOKEN' });
    }
    if (error.name === 'TokenExpiredError') {
      return res
        .status(401)
        .json({ error: 'License token expired', code: 'LICENSE_TOKEN_EXPIRED' });
    }
    res.status(500).json({ error: 'License verification error', code: 'LICENSE_ERROR' });
  }
};

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
