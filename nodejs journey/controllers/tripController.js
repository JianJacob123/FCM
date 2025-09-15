const tripModels = require('../models/tripModels');
const vehicleModels = require('../models/vehicleModels');
const routeModels = require('../models/routeModels');
const routeMappingModels = require('../models/routeMappingModels');
const geolib = require('geolib');

// --- Geofence with hysteresis ---
function getGeofenceState(lat, lng, targetLat, targetLng, prevState, enterRadius = 150, exitBuffer = 30) {
  const distance = geolib.getDistance(
    { latitude: lat, longitude: lng },
    { latitude: targetLat, longitude: targetLng }
  );

  const exitRadius = enterRadius + exitBuffer;
  console.log(`Distance to target (${targetLat},${targetLng}): ${distance}m (prevState=${prevState})`);

  if (prevState) {
    // Already inside → only exit if fully outside
    return distance <= exitRadius;
  } else {
    // Currently outside → only enter if fully inside
    return distance <= enterRadius;
  }
}

const startTripIfInGeofence = async () => {
  try { 
    const vehicles = await vehicleModels.getAllVehicles();

    for (const vehicle of vehicles) {
      const { vehicle_id, lat, lng, route_id } = vehicle;

      if (!route_id) {
        console.log(`Vehicle ${vehicle_id} has no assigned route.`);
        continue;
      }

      const route = await routeModels.getRouteById(route_id);
      if (!route) {
        console.log(`Route ${route_id} not found for vehicle ${vehicle_id}.`);
        continue;
      }

      const { start_lat, start_lng, end_lat, end_lng } = route;

      const prevState = await tripModels.fetchGeofenceState(vehicle_id);

      // --- Apply hysteresis geofence check ---
      const insideStart = getGeofenceState(lat, lng, start_lat, start_lng, prevState.at_start);
      const insideEnd = getGeofenceState(lat, lng, end_lat, end_lng, prevState.at_end);


      // --- Start trip when entering start geofence ---
      if (insideStart && !prevState.at_start) {
        const activeTrip = await tripModels.getActiveTripsByVehicle(vehicle_id);
        if (!activeTrip || activeTrip.length === 0) {
          await tripModels.insertTrip(vehicle_id, lat, lng, 'active');
          console.log(`Trip started for vehicle ${vehicle_id}`);
        } else {
          console.log(`Vehicle ${vehicle_id} already has an active trip.`);
        }

        await tripModels.updateGeofenceState(vehicle_id, {
          at_start: true,
          at_end: false
        });
      }

      // --- End trip when entering end geofence ---
      else if (insideEnd && !prevState.at_end) {
        const activeTrip = await tripModels.getActiveTripsByVehicle(vehicle_id);

        if (activeTrip && activeTrip.length > 0) {
          const toRouteId = await routeMappingModels.getToRouteId(route_id);

          await tripModels.endTrip(vehicle_id, lat, lng, 'completed');
          console.log(`Trip completed for vehicle ${vehicle_id}`);

          if (toRouteId) {
            await vehicleModels.updateRouteId(vehicle_id, toRouteId);
          } else {
            console.log(`No mapped route found for vehicle ${vehicle_id} after trip completion.`);
          }

          await tripModels.updateGeofenceState(vehicle_id, {
            at_start: false,
            at_end: true
          });
        }
      }

      // --- Update exit detection ---
      else {
        if (!insideStart && prevState.at_start) {
          await tripModels.updateGeofenceState(vehicle_id, { at_start: false, at_end:  prevState.at_end });
          console.log(`Vehicle ${vehicle_id} exited start geofence`);
        }

        if (!insideEnd && prevState.at_end) {
          await tripModels.updateGeofenceState(vehicle_id, { at_start: prevState.at_start, at_end: false });
          console.log(`Vehicle ${vehicle_id} exited end geofence`);
        }
      }
    }

    console.log('Geofence checks done')
  } catch (err) {
    console.error('Error in geofence check:', err);
  }
};

module.exports = {
  startTripIfInGeofence
};
