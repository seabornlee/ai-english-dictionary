// @ts-check
const { logger } = require('./logger');

/**
 * Simple feature flag system backed by environment variables.
 * Flags are prefixed with FEATURE_ and default to false unless explicitly enabled.
 */

/** @type {Record<string, boolean>} */
const FLAG_DEFAULTS = {
  NEW_SIGNIN: false,
  VOCABULARY_SYNC: false,
  EXPERIMENTAL_API: false,
};

/**
 * Check if a feature flag is enabled.
 * @param {string} name - Flag name (without FEATURE_ prefix)
 * @returns {boolean}
 */
const isFeatureEnabled = name => {
  if (!(name in FLAG_DEFAULTS)) {
    logger.warn({ flag: name }, 'Unknown feature flag checked');
    return false;
  }
  const envValue = process.env[`FEATURE_${name}`];
  if (envValue === undefined) {
    return FLAG_DEFAULTS[name];
  }
  return envValue === 'true' || envValue === '1';
};

/**
 * Get all feature flags and their current state.
 * @returns {Record<string, boolean>}
 */
const getAllFlags = () => {
  return Object.fromEntries(Object.keys(FLAG_DEFAULTS).map(name => [name, isFeatureEnabled(name)]));
};

module.exports = { isFeatureEnabled, getAllFlags, FLAG_DEFAULTS };
