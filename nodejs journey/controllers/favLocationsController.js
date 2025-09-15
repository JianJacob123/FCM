const favLocationModel = require('../models/favLocationsModels');
const mapBox = require('../services/mapBoxServices')

const getFavoriteLocations = async (req, res) => {
    const userId = req.query.id;
    try {
        const locations = await favLocationModel.getFavoriteLocationsByUserId(userId);
        res.status(200).json(locations);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch favorite locations' });
    }
}

const addFavoriteLocation = async (req, res) => {
    const { passenger_id, lat, lng } = req.body;
    try {
        const locationName = await mapBox.getNameFromCoordinates(lat, lng)
        if (locationName) {
            const newLocation = await favLocationModel.addFavoriteLocation(passenger_id, locationName, lat, lng);
            res.status(201).json(newLocation);
        } else {
            console.log("locationName not found")
        }
    } catch (error) {
        res.status(500).json({ error: 'Failed to add favorite location' });
    }
}

module.exports = {
    getFavoriteLocations,
    addFavoriteLocation
};