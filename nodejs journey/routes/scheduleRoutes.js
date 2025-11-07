const router = require('express').Router();
const ctrl = require('../controllers/scheduleControllers');
const { cacheMiddleware } = require('../middleware/cacheMiddleware');
const { analyticsRateLimiter } = require('../middleware/rateLimitMiddleware');

// Apply caching (5 minutes) and rate limiting to GET endpoint
router.get('/api/schedules', analyticsRateLimiter, cacheMiddleware(300), ctrl.getByDate);
router.post('/api/schedules', ctrl.create);
router.put('/api/schedules/:id', ctrl.update);
router.delete('/api/schedules/:id', ctrl.remove);

module.exports = router;


