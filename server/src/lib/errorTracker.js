// @ts-check
const { logger } = require('./logger');

/**
 * Error tracking utility.
 * Captures errors with context and logs them in a structured way.
 * Can be extended to send to external error tracking services (Sentry, Bugsnag).
 */

/**
 * Track an error with optional context.
 * @param {Error} error
 * @param {Record<string, unknown>} [context]
 */
const trackError = (error, context = {}) => {
  const err = /** @type {Error & {code?: string, statusCode?: number}} */ (error);
  const errorInfo = {
    name: err.name,
    message: err.message,
    stack: err.stack,
    code: err.code,
    statusCode: err.statusCode,
    ...context,
  };
  logger.error(errorInfo, `Error tracked: ${err.message}`);
};

/**
 * Track a warning with context.
 * @param {string} message
 * @param {Record<string, unknown>} [context]
 */
const trackWarning = (message, context = {}) => {
  logger.warn(context, message);
};

/**
 * Wrap an async handler to automatically track unhandled errors.
 * @param {Function} handler
 * @returns {Function}
 */
const withErrorTracking = handler => {
  return async (...args) => {
    try {
      return await handler(...args);
    } catch (error) {
      trackError(/** @type {Error} */ (error));
      throw error;
    }
  };
};

module.exports = { trackError, trackWarning, withErrorTracking };
