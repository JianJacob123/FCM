const express = require('express');
const router = express.Router();
const tripController = require('../controllers/tripController');

router.post('/check-geofence', tripController.startTripIfInGeofence);
router.get('/trip-count', tripController.fetchTripDetails);


module.exports = router;