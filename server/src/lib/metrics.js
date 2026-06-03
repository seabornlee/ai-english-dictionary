// @ts-check
const { logger } = require('./logger');

/**
 * Simple in-memory metrics collection.
 * Tracks response times, request counts, and error rates per endpoint.
 */

/** @type {Map<string, {count: number, totalMs: number, errors: number, minMs: number, maxMs: number}>} */
const metrics = new Map();

/**
 * Record a request metric.
 * @param {string} method
 * @param {string} path
 * @param {number} durationMs
 * @param {number} statusCode
 */
const record = (method, path, durationMs, statusCode) => {
  const key = `${method} ${path}`;
  const entry = metrics.get(key) ?? {
    count: 0,
    totalMs: 0,
    errors: 0,
    minMs: Infinity,
    maxMs: 0,
  };
  entry.count += 1;
  entry.totalMs += durationMs;
  entry.minMs = Math.min(entry.minMs, durationMs);
  entry.maxMs = Math.max(entry.maxMs, durationMs);
  if (statusCode >= 500) {
    entry.errors += 1;
  }
  metrics.set(key, entry);
};

/**
 * Get all collected metrics.
 * @returns {Record<string, {count: number, avgMs: number, minMs: number, maxMs: number, errors: number, errorRate: string}>}
 */
const getAll = () => {
  const result = {};
  for (const [key, entry] of metrics) {
    result[key] = {
      count: entry.count,
      avgMs: Math.round(entry.totalMs / entry.count),
      minMs: entry.minMs === Infinity ? 0 : Math.round(entry.minMs),
      maxMs: Math.round(entry.maxMs),
      errors: entry.errors,
      errorRate: entry.count > 0 ? `${((entry.errors / entry.count) * 100).toFixed(1)}%` : '0%',
    };
  }
  return result;
};

/** Reset all metrics. */
const reset = () => {
  metrics.clear();
};

/**
 * Express middleware to collect response time metrics.
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
const metricsMiddleware = (req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const durationMs = Date.now() - start;
    const path = req.route?.path ?? req.path;
    record(req.method, path, durationMs, res.statusCode);
  });
  next();
};

/** Log a metrics summary. */
const logSummary = () => {
  const data = getAll();
  const totalRequests = Object.values(data).reduce((sum, e) => sum + e.count, 0);
  if (totalRequests === 0) return;
  logger.info({ totalRequests, endpoints: Object.keys(data).length }, 'Metrics summary');
};

module.exports = { metricsMiddleware, getAll, reset, logSummary, record };
