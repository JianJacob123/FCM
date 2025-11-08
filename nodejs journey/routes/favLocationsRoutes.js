const express = require('express');
const router = express.Router();
const favLocationController = require('../controllers/favLocationsController');

router.get('/getFavLocation', favLocationController.getFavoriteLocations);
router.post('/addFavLocation', favLocationController.addFavoriteLocation);
router.delete('/removeFavLocation/:favoriteLocationId', favLocationController.removeFavoriteLocation);

module.exports = router;