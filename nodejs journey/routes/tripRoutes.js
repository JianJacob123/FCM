const express = require('express');
const router = express.Router();
const metricsCtrl = require('../controllers/tripControllers');
const tripController = require('../controllers/tripController');

// Existing routes
router.post('/check-geofence', tripController.startTripIfInGeofence);
router.get('/trip-count', tripController.fetchTripDetails);

// New metrics route
router.get('/api/trips-per-unit', metricsCtrl.tripsPerUnit);
router.get('/api/fleet-activity', metricsCtrl.fleetActivityByHour);

// Admin trips route
router.get('/api/admin/trips', metricsCtrl.getAllTripsForAdmin);
router.get('/api/trips-by-date', metricsCtrl.getTripsByDate);

// Today's passenger count route
router.get('/api/today-passengers', metricsCtrl.getTodayPassengerCount);

module.exports = router;