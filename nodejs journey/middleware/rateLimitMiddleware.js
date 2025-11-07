const rateLimit = require('express-rate-limit');

/**
 * General rate limiter for analytics endpoints
 * Allows 30 requests per minute per IP
 */
const analyticsRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // 30 requests per minute
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: 60
  },
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  skip: (req) => {
    // Skip rate limiting for localhost in development
    return process.env.NODE_ENV === 'development' && req.ip === '::1';
  }
});

/**
 * Stricter rate limiter for expensive operations
 * Allows 10 requests per minute per IP
 */
const strictRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 requests per minute
  message: {
    error: 'Too many requests for this resource, please try again later.',
    retryAfter: 60
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    return process.env.NODE_ENV === 'development' && req.ip === '::1';
  }
});

/**
 * Per-route rate limiter (configurable)
 * @param {number} max - Maximum requests per window
 * @param {number} windowMs - Time window in milliseconds
 */
const createRateLimiter = (max = 30, windowMs = 60 * 1000) => {
  return rateLimit({
    windowMs,
    max,
    message: {
      error: 'Too many requests, please try again later.',
      retryAfter: Math.ceil(windowMs / 1000)
    },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => {
      return process.env.NODE_ENV === 'development' && req.ip === '::1';
    }
  });
};

module.exports = {
  analyticsRateLimiter,
  strictRateLimiter,
  createRateLimiter
};

