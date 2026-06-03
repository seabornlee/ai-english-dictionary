// @ts-check
const admin = require('firebase-admin');

/**
 * Lazy-initialized Firebase Admin SDK.
 * Initialized from FIREBASE_SERVICE_ACCOUNT (JSON string) or
 * GOOGLE_APPLICATION_CREDENTIALS (path to service account file).
 */

let _app = null;

/**
 * Get the Firebase Admin app instance (lazy-initialized).
 * @returns {admin.app.App}
 */
const getApp = () => {
  if (_app) return _app;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  const credentialPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (serviceAccountJson) {
    try {
      const serviceAccount = JSON.parse(serviceAccountJson);
      _app = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      return _app;
    } catch (e) {
      /** @type {Error} */ (e).message =
        `Failed to parse FIREBASE_SERVICE_ACCOUNT: ${/** @type {Error} */ (e).message}`;
      throw e;
    }
  }

  if (credentialPath) {
    _app = admin.initializeApp({
      credential: admin.credential.cert(credentialPath),
    });
    return _app;
  }

  throw new Error(
    'Firebase Admin not configured. Set FIREBASE_SERVICE_ACCOUNT or GOOGLE_APPLICATION_CREDENTIALS.'
  );
};

/**
 * Verify a Firebase ID token and return the decoded claims.
 * @param {string} idToken - The Firebase ID token to verify.
 * @returns {Promise<admin.auth.DecodedIdToken>}
 */
const verifyIdToken = async idToken => {
  const app = getApp();
  return admin.auth(app).verifyIdToken(idToken);
};

/**
 * Get a user by their Firebase UID.
 * @param {string} uid - The Firebase UID.
 * @returns {Promise<admin.auth.UserRecord>}
 */
const getUserByUid = async uid => {
  const app = getApp();
  return admin.auth(app).getUser(uid);
};

module.exports = { getApp, verifyIdToken, getUserByUid };
