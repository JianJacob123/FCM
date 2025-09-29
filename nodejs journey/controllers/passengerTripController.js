const passengerTripModel = require('../models/passengerTripModels');
const vehicleModel = require('../models/vehicleModels');
const geolib = require('geolib');

const createRequest = (io) => async (req, res) => {
    const { passengerId, pickupLat, pickupLng, dropoffLat, dropoffLng, routeId } = req.body;
    try {
        const newRequest = await passengerTripModel.insertRequest(passengerId, pickupLat, pickupLng, dropoffLat, dropoffLng,'pending', routeId);
        res.status(201).json(newRequest);

        io.to(`trip_${passengerId}`).emit("tripCreate", {
        requestId,
        status: "pending"

});
    } catch (error) {
        console.error('Error creating request:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
}

// --- SERVICE FUNCTIONS (no req/res here) ---
const checkVehicleNearPickUp = async (io) => {
   try {
        const pendingTrips = await passengerTripModel.getAllPendingRequests('pending');
        if (!pendingTrips || pendingTrips.length === 0) {
            console.log('[CRON] No pending requests found.');
            return [];
        }

        const vehicles = await vehicleModel.getAllVehicles(); 
        let updatedTrips = [];

        for (const trip of pendingTrips) {
            const passengerLocation = {
                latitude: trip.pickup_lat,
                longitude: trip.pickup_lng
            };

            const nearbyVehicle = vehicles.reduce((closest, vehicle) => {
                const distance = geolib.getDistance(passengerLocation, {
                    latitude: vehicle.lat,
                    longitude: vehicle.lng
                });

                if (distance <= 100 && (!closest || distance < closest.distance)) {
                    return { vehicle, distance };
                }
                return closest;
            }, null);

            if (nearbyVehicle) {
                await passengerTripModel.updateRequestPickedUp(
                    trip.request_id,
                    'picked_up',
                    nearbyVehicle.vehicle.vehicle_id
                );

                io.to(`trip_${trip.passenger_id}`).emit("tripUpdate", {
                requestId: trip.request_id,
                status: "picked_up"
                });

                const notif = await notificationModels.createNotification(
                            'Bus Near Pickup',
                            'proximity',
                            `FCM Unit ${nearbyVehicle.vehicle.vehicle_id} is near your pickup location.`,
                            new Date()
                          );
                          io.of("/notifications").to(`user_${trip.passenger_id}`).emit("newNotification", notif);

                updatedTrips.push({
                    request_id: trip.request_id,
                    passenger_id: trip.passenger_id,
                    vehicle_id: nearbyVehicle.vehicle.vehicle_id,
                    status: 'picked_up'
                });
            }
        }

        console.log(updatedTrips.length > 0
            ? '[CRON] Trips marked as picked up:' + JSON.stringify(updatedTrips)
            : '[CRON] No vehicles near any pending pickups.');

        return updatedTrips;

    } catch (error) {
        console.error('Error checking pickups:', error);
        return [];
    }
};

const checkDropoffs = async (io) => {
  
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
        console.warn(`Trip ${trip.request_id} has no dropoff coordinates, skipping.`);
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
        await passengerTripModel.updateTripStatus(trip.request_id, "dropped_off");

        io.to(`trip_${trip.passenger_id}`).emit("tripUpdate", {
        requestId: trip.request_id,
        status: "dropped_off"
        });

        completedTrips.push(trip.vehicle_id);
        console.log(`Trip ${trip.vehicle_id} marked as completed!`);

        const notif = await notificationModels.createNotification(
                            'Bus Near Dropoff',
                            'proximity',
                            `FCM Unit ${vehicle.vehicle_id} is near your dropoff location.`,
                            new Date()
                          );
        io.of("/notifications").to(`user_${trip.passenger_id}`).emit("newNotification", notif);
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

const getCompletedTripsById = async (req, res) => {
    const passengerId = req.params.id;
    try {
        const trips = await passengerTripModel.getCompletedTripsById(passengerId);
        res.status(200).json(trips);
    } catch (error) {
        console.error('Error fetching completed trips:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
  }

const fetchPendingTrips = async (req, res) => {
    try {
        const trips = await passengerTripModel.getPendingTrips();
        res.status(200).json(trips);
    } catch (error) {
        console.error('Error fetching pickup trips:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
  }


module.exports = {
    createRequest,
    checkVehicleNearPickUp,
    checkDropoffs,
    isVehicleNearPickUp,
    monitorDropoffs,
    getCompletedTripsById,
    fetchPendingTrips
};