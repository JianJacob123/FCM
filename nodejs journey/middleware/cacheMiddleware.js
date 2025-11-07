const NodeCache = require('node-cache');

// Create cache instance with 5-minute default TTL
const cache = new NodeCache({
  stdTTL: 300, // 5 minutes default
  checkperiod: 60, // Check for expired keys every minute
  useClones: false // Better performance for large objects
});

/**
 * Middleware to cache GET requests
 * @param {number} ttl - Time to live in seconds (default: 300 = 5 minutes)
 * @returns {Function} Express middleware
 */
const cacheMiddleware = (ttl = 300) => {
  return (req, res, next) => {
    // Only cache GET requests
    if (req.method !== 'GET') {
      return next();
    }

    // Generate cache key from URL and query params
    const cacheKey = `${req.originalUrl || req.url}`;
    
    // Check if cached response exists
    const cachedResponse = cache.get(cacheKey);
    if (cachedResponse) {
      console.log(`[CACHE HIT] ${cacheKey}`);
      return res.json(cachedResponse);
    }

    // Store original json method
    const originalJson = res.json.bind(res);
    
    // Override res.json to cache the response
    res.json = function(data) {
      // Cache the response
      cache.set(cacheKey, data, ttl);
      console.log(`[CACHE SET] ${cacheKey} (TTL: ${ttl}s)`);
      
      // Call original json method
      return originalJson(data);
    };

    next();
  };
};

/**
 * Clear cache for a specific pattern
 * @param {string} pattern - Pattern to match cache keys (supports wildcards)
 */
const clearCache = (pattern) => {
  const keys = cache.keys();
  const regex = new RegExp(pattern.replace('*', '.*'));
  let cleared = 0;
  
  keys.forEach(key => {
    if (regex.test(key)) {
      cache.del(key);
      cleared++;
    }
  });
  
  console.log(`[CACHE CLEAR] Cleared ${cleared} keys matching pattern: ${pattern}`);
  return cleared;
};

/**
 * Clear all cache
 */
const clearAllCache = () => {
  const count = cache.keys().length;
  cache.flushAll();
  console.log(`[CACHE CLEAR] Cleared all ${count} cached entries`);
  return count;
};

module.exports = {
  cacheMiddleware,
  clearCache,
  clearAllCache,
  cache // Export cache instance for direct access if needed
};

