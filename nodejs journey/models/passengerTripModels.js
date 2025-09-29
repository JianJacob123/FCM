const client = require('../config/db'); //db connection file

const getAllRequestsByPassengerId = async (passengerId) => {
    const sql = `SELECT * FROM passenger_trip WHERE passenger_id = $1`;
    const res = await client.query(sql, [passengerId]);
    return res.rows;
}

const getAllPendingRequests = async (status) => { //for automation to check pending requests
    try {
        const res = await client.query('SELECT * FROM passenger_trip WHERE status = $1', [status]);
        return res.rows;
    } catch (err) {
        console.error('Error fetching vehicles:', err);
        throw err;
    }
}

const insertRequest = async (passengerId, pickupLat, pickupLng, dropoffLat, dropoffLng, status, routeId) => {
    const sql = `INSERT INTO passenger_trip (passenger_id, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, status, route_id) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`;
    const res = await client.query(sql, [passengerId, pickupLat, pickupLng, dropoffLat, dropoffLng, status, routeId]);
    return res.rows[0];
}

const updateRequestPickedUp = async (requestId, status, vehicleId) => {
    const sql = `UPDATE passenger_trip SET status = $1, vehicle_id = $2 WHERE request_id = $3 RETURNING *`;
    const res = await client.query(sql, [status, vehicleId,  requestId]);
    return res.rows[0];
}

const getPickupLocation = async (passengerId) => {
    const sql = `SELECT pickup_lat, pickup_lng FROM passenger_trip WHERE passenger_id = $1 AND status = 'pending'`;
    const res = await client.query(sql, [passengerId]);
    return res.rows[0];
}



const getAllOngoingTrips = async (status) => {
    const sql = `SELECT * FROM passenger_trip WHERE status = $1`;
    const res = await client.query(sql, [status]);
    return res.rows;
}

const updateTripStatus = async (tripId, status) => {
  try {
    const sql = `UPDATE passenger_trip 
                 SET status = $1 
                 WHERE request_id = $2 
                 RETURNING *`;
    const res = await client.query(sql, [status, tripId]);
    return res.rows[0]; // return the updated trip
  } catch (err) {
    console.error('Error updating trip status:', err);
    throw err;
  }
};

const getCompletedTripsById = async (passengerId) => {
    const sql = `SELECT * FROM passenger_trip WHERE passenger_id = $1 AND status = 'dropped_off'`;
    const res = await client.query(sql, [passengerId]);
    return res.rows;
}

const getPendingTrips = async () => { //For Conductor Side
    const sql = `SELECT passenger_id, pickup_lat, pickup_lng, created_at, route_name FROM passenger_trip
INNER JOIN routes
ON routes.route_id = 
passenger_trip.route_id
WHERE status = 'pending'`;
    const res = await client.query(sql);
    return res.rows;
}

module.exports = {
    getAllRequestsByPassengerId,
    getAllPendingRequests,
    insertRequest,
    updateRequestPickedUp,
    getPickupLocation,
    getAllOngoingTrips,
    updateTripStatus,
    getCompletedTripsById,
    getPendingTrips
};