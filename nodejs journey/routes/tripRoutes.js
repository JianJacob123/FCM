const express = require('express');
const router = express.Router();
const metricsCtrl = require('../controllers/tripControllers');
const tripController = require('../controllers/tripController');
const { cacheMiddleware } = require('../middleware/cacheMiddleware');
const { analyticsRateLimiter } = require('../middleware/rateLimitMiddleware');

// Existing routes (no caching/rate limiting for real-time operations)
router.post('/check-geofence', tripController.startTripIfInGeofence);
router.get('/trip-count', tripController.fetchTripDetails);

// Analytics routes with caching (5 minutes) and rate limiting
router.get('/api/trips-per-unit', analyticsRateLimiter, cacheMiddleware(300), metricsCtrl.tripsPerUnit);
router.get('/api/fleet-activity', analyticsRateLimiter, cacheMiddleware(300), metricsCtrl.fleetActivityByHour);
router.get('/api/trips-by-date', analyticsRateLimiter, cacheMiddleware(300), metricsCtrl.getTripsByDate);
router.get('/api/today-passengers', analyticsRateLimiter, cacheMiddleware(300), metricsCtrl.getTodayPassengerCount);

// Admin trips route (no caching for admin operations)
router.get('/api/admin/trips', metricsCtrl.getAllTripsForAdmin);

module.exports = router;