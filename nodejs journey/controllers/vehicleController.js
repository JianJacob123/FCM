const vehicleModel = require('../models/vehicleModels');
const coordinatesData = require('../services/coordinates');

const getVehicles = async (req, res) => {
    try {
        const vehicles = await vehicleModel.getAllVehicles();
        res.json(vehicles);
    } catch (err) {
        console.error('Error fetching vehicles:', err);
        res.status(500).json({ error: err.message });
    }
}

const updateCoordinatesLogic = async () => {
    try {
        const iotResponse = await coordinatesData.getIoTData();
        
        for (const vehicle of iotResponse) {
            await vehicleModel.updateVehicleCoordinates(
                vehicle.vehicle_id, 
                vehicle.lat,
                vehicle.lng
            );
        }
        console.log('Coordinates updated successfully');
    } catch (err) {
        console.error('Error fetching IoT data:', err);
        // Just throw the error to be handled by the caller
        throw err;
    }
}

const updateCoordinates = async (req, res) => {
    try {
    await updateCoordinatesLogic();
    res.json({ message: 'Coordinates updated from IoT data' });
  } catch (err) {
    console.error('Error fetching IoT data:', err);
    res.status(500).json({ error: err.message });
  }
};


module.exports = {
    getVehicles,
    updateCoordinates,
    updateCoordinatesLogic
};