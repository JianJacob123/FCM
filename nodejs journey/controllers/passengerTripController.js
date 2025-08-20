const passengerTripModel = require('../models/passengerTripModels');
const vehicleModel = require('../models/vehicleModels');
const geolib = require('geolib');

const createRequest = async (req, res) => {
    const { passengerId, pickupLat, pickupLng } = req.body;
    try {
        const newRequest = await passengerTripModel.insertRequest(passengerId, pickupLat, pickupLng, 'pending');
        res.status(201).json(newRequest);
    } catch (error) {
        console.error('Error creating request:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
}

// --- SERVICE FUNCTIONS (no req/res here) ---
const checkVehicleNearPickUp = async () => {
   try {
        // 1. Get all pending passenger requests
        const pendingTrips = await passengerTripModel.getAllPendingRequests('pending');

        if (!pendingTrips || pendingTrips.length === 0) {
            console.log('[CRON] No pending requests found.');
        }

        // 2. Get latest vehicle locations
        const vehicles = await vehicleModel.getAllVehicles(); 

        let updatedTrips = [];

        // 3. Loop through each passenger trip
        for (const trip of pendingTrips) {
            const passengerLocation = {
                latitude: trip.pickup_lat,
                longitude: trip.pickup_lng
            };

            // 4. Check if any vehicle is near this passenger
            const nearbyVehicle = vehicles.find(vehicle => {
                const distance = geolib.getDistance(
                    passengerLocation,
                    {
                        latitude: vehicle.lat,
                        longitude: vehicle.lng
                    }
                );
                return distance <= 100; // e.g. 100 meters threshold
            });

            // 5. If a nearby vehicle is found, update status
            if (nearbyVehicle) {
                await passengerTripModel.updateRequestPickedUp(trip.request_id, 'picked_up', nearbyVehicle.vehicle_id);
                updatedTrips.push({
                    request_id: trip.request_id,
                    passenger_id: trip.passenger_id,
                    vehicle_id: nearbyVehicle.id,
                    status: 'picked_up'
                });
            }
        }

        if (updatedTrips.length > 0) {
            console.log('[CRON] Trips marked as picked up:', updatedTrips);
        } else {
            console.log('[CRON] No vehicles near any pending pickups.');
        }

    } catch (error) {
        console.error('Error checking pickups:', error);
    }
}

const checkDropoffs = async () => {
  try {
    const trips = await passengerTripModel.getAllOngoingTrips("picked_up");
    const completedTrips = [];

    for (const trip of trips) {
      if (!trip) {
        console.warn("Skipping undefined trip");
        continue;
      }

      // Ensure dropoff coords exist
      if (!trip.dropoff_lat || !trip.dropoff_lng) {
        console.warn(`Trip ${trip.id} has no dropoff coordinates, skipping.`);
        continue;
      }

      // Get vehicle location
      const vehicle = await vehicleModel.getVehicleById(trip.vehicle_id);
      if (!vehicle || !vehicle.lat || !vehicle.lng) {
        console.warn(`Vehicle ${trip.vehicle_id} not found or missing coordinates.`);
        continue;
      }

      // Calculate distance
      const distance = geolib.getDistance(
        { latitude: vehicle.lat, longitude: vehicle.lng },
        { latitude: trip.dropoff_lat, longitude: trip.dropoff_lng }
      );

      if (distance <= 50 && trip.status === "picked_up") {
        await passengerTripModel.updateTripStatus(trip.id, "dropped_off");
        completedTrips.push(trip.vehicle_id);
        console.log(`Trip ${trip.vehicle_id} marked as completed!`);
      }
    }

    return completedTrips;
  } catch (err) {
    console.error("Error monitoring dropoffs:", err);
    return [];
  }
}

// --- CONTROLLERS (wrap service for HTTP routes) ---
const isVehicleNearPickUp = async (req, res) => {
  try {
    const result = await checkVehicleNearPickUp();
    res.status(200).json(result);
  } catch (error) {
    console.error('Error checking pickups:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};

const monitorDropoffs = async (req, res) => {
  try {
    const completedTrips = await checkDropoffs();
    res.status(200).json({
      message: 'Dropoff check completed',
      completedTrips
    });
  } catch (error) {
    console.error('Error monitoring dropoffs:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
};


module.exports = {
    createRequest,
    checkVehicleNearPickUp,
    checkDropoffs,
    isVehicleNearPickUp,
    monitorDropoffs
};