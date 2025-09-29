const passengerTripController = require('../controllers/passengerTripController');
const express = require('express');
const router = express.Router();

router.get('/getCompletedtrips', passengerTripController.getCompletedTripsById);
router.get('/fetchPendingTrips', passengerTripController.fetchPendingTrips);
router.post('/createRequest', passengerTripController.createRequest);

module.exports = router;