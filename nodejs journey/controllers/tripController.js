const tripModels = require('../models/tripModels');
const vehicleModels = require('../models/vehicleModels');
const routeModels = require('../models/routeModels');
const routeMappingModels = require('../models/routeMappingModels');

const startTripIfInGeofence = async (req, res) => {
    try {
        const vehicles = await vehicleModels.getAllVehicles();

        for (const vehicle of vehicles) {
            const { vehicle_id, lat, lng, route_id } = vehicle;

            if(!route_id) {
                console.log(`Vehicle ${vehicle_id} has no assigned route.`);
                continue;
            };

            const route = await routeModels.getRouteById(route_id);
            if (!route) {
                console.log(`Route ${route_id} not found for vehicle ${vehicle_id}.`);
                continue;
            }

            const { start_lat, start_lng, end_lat, end_lng } = route;

            // Example: basic bounding box check for geofence
            if (lat === start_lat && lng === start_lng) {

                // Check if there's already an active trip
                const activeTrip = await tripModels.getActiveTripsByVehicle(vehicle_id);
                if (!activeTrip || activeTrip.length === 0) {
                    await tripModels.insertTrip(vehicle_id, lat, lng, 'active');
                    console.log(`Trip started for vehicle ${vehicle_id}`);
                } else {
                    console.log(`Vehicle ${vehicle_id} already has an active trip.`);
                }
            } else if (lat === end_lat && lng === end_lng) {
                const activeTrip = await tripModels.getActiveTripsByVehicle(vehicle_id);

                if (activeTrip && activeTrip.length > 0) {
                    const toRouteId = await routeMappingModels.getToRouteId(route_id);

                    await tripModels.endTrip(vehicle_id, lat, lng, 'completed');
                    console.log(`Trip completed for vehicle ${vehicle_id}`);
                    if(toRouteId) {
                    await vehicleModels.updateRouteId(vehicle_id, toRouteId);
                    } else {
                        console.log(`No mapped route found for vehicle ${vehicle_id} after trip completion.`);
                    }
                }
            }
        }

        res.json({ message: 'Trips checked and inserted if in geofence' });

    } catch (err) {
        console.error('Error starting trip:', err);
        res.status(500).json({ error: err.message });
    }
};

module.exports = {
    startTripIfInGeofence 
};