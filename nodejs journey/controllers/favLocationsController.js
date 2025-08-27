const favLocationModel = require('../models/favLocationsModels');

const getFavoriteLocations = async (req, res) => {
    const userId = req.params.userId;
    try {
        const locations = await favLocationModel.getFavoriteLocationsByUserId(userId);
        res.status(200).json(locations);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch favorite locations' });
    }
}

const addFavoriteLocation = async (req, res) => {
    const userId = req.params.userId;
    const { locationName } = req.body;
    try {
        const newLocation = await favLocationModel.addFavoriteLocation(userId, locationName);
        res.status(201).json(newLocation);
    } catch (error) {
        res.status(500).json({ error: 'Failed to add favorite location' });
    }
}

module.exports = {
    getFavoriteLocations,
    addFavoriteLocation
};