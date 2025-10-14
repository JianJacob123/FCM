const vehicleModel = require('../models/vehicleModels');

const getVehicles = async (req, res) => {
    try {
        const vehicles = await vehicleModel.getAllVehicles();
        res.json(vehicles);
    } catch (err) {
        console.error('Error fetching vehicles:', err);
        res.status(500).json({ error: err.message });
    }
}

// This is for internal use (not req/res based)
const getVehiclesDirect = async () => {
  return await vehicleModel.getAllVehicles();
};

const updateCoordinatesLogic = async (io, iotResponse) => {
    let addedPassengers = 0;
    try {
        
        //const iotResponse = await coordinatesData.getIoTData();

        if (!iotResponse) {
            console.warn('No IoT data available yet');
            return;
        }
        
        // Normalize: always work with an array
        const vehicles = Array.isArray(iotResponse) ? iotResponse : [iotResponse];
        
        for (const vehicle of vehicles) {
            const currentCount = await vehicleModel.getCurrentPassengerCount(vehicle.bus_id);
            console.log(currentCount);

            // To extract the added passengers from the current_passenger_count
            if (vehicle.passenger_count > currentCount) {
                addedPassengers = vehicle.passenger_count - currentCount;
                console.log('Added passengers:', addedPassengers);
            } else {
                addedPassengers = 0; // No negative subtraction
            }

            await vehicleModel.updateVehicleCoordinates(
                vehicle.bus_id, 
                vehicle.lat,
                vehicle.lon,
                vehicle.passenger_count,
                addedPassengers
            );
        }
        console.log('Coordinates updated successfully');

    const updatedVehicles = await vehicleModel.getAllVehicles();
    io.of("/vehicles").to("vehicleRoom").emit("vehicleUpdate", updatedVehicles);

    // Emit to each conductor (only their assigned vehicle)
        for (const vehicle of updatedVehicles) {
            // find which conductor is assigned to this vehicle
            // you’d query your `vehicle_assignment` table here
            const conductorId = await vehicleModel.getConductorIdByVehicle(vehicle.vehicle_id);
            if (conductorId) {
                const conductorVehicle = await vehicleModel.getVehicleByConductor(conductorId);
                io.of("/vehicles").to(`conductor:${conductorId}`).emit("vehicleUpdate", conductorVehicle);
            }
        }

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
    getVehiclesDirect,
    updateCoordinates,
    updateCoordinatesLogic
};