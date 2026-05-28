// @ts-check
const pino = require('pino');

/**
 * Sensitive fields to redact from logs
 */
const REDACT_PATHS = [
  'password',
  'token',
  'authorization',
  'apiKey',
  'api_key',
  'secret',
  'creditCard',
  'ssn',
  'email',
  '*.password',
  '*.token',
  '*.apiKey',
  '*.secret',
  'req.headers.authorization',
  'req.headers.cookie',
  'res.headers["set-cookie"]',
];

/**
 * Create logger instance with structured logging and log scrubbing
 */
const logger = pino({
  level: process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug'),
  redact: {
    paths: REDACT_PATHS,
    censor: '[REDACTED]',
  },
  formatters: {
    level: label => ({ level: label }),
    bindings: bindings => ({
      pid: bindings.pid,
      host: bindings.hostname,
      node_version: process.version,
    }),
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  base: {
    service: 'ai-dic-server',
    env: process.env.NODE_ENV || 'development',
  },
  transport:
    process.env.NODE_ENV !== 'production'
      ? {
          target: 'pino-pretty',
          options: {
            colorize: true,
            translateTime: 'SYS:standard',
            ignore: 'pid,hostname',
          },
        }
      : undefined,
});

/**
 * Create a child logger with additional context
 * @param {object} context - Additional context to include in logs
 * @returns {pino.Logger}
 */
function createChildLogger(context) {
  return logger.child(context);
}

/**
 * Express request logging middleware
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
function requestLogger(req, res, next) {
  const startTime = Date.now();
  const requestId =
    req.headers['x-request-id'] || `req-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

  // Attach request ID to request object
  // @ts-ignore
  req.requestId = requestId;

  // Create child logger with request context
  const reqLogger = logger.child({
    requestId,
    method: req.method,
    url: req.url,
    userAgent: req.headers['user-agent'],
  });

  // @ts-ignore
  req.log = reqLogger;

  // Log request start
  reqLogger.info({ type: 'request_start' }, `${req.method} ${req.url}`);

  // Log response when finished
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const logData = {
      type: 'request_end',
      statusCode: res.statusCode,
      duration,
    };

    if (res.statusCode >= 500) {
      reqLogger.error(logData, `${req.method} ${req.url} - ${res.statusCode} (${duration}ms)`);
    } else if (res.statusCode >= 400) {
      reqLogger.warn(logData, `${req.method} ${req.url} - ${res.statusCode} (${duration}ms)`);
    } else {
      reqLogger.info(logData, `${req.method} ${req.url} - ${res.statusCode} (${duration}ms)`);
    }
  });

  next();
}

module.exports = {
  logger,
  createChildLogger,
  requestLogger,
};
