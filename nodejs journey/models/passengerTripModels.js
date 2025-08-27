const client = require('../config/db'); //db connection file

const getAllRequestsByPassengerId = async (passengerId) => {
    const sql = `SELECT * FROM passenger_trip WHERE passenger_id = $1`;
    const res = await client.query(sql, [passengerId]);
    return res.rows;
}

const getAllPendingRequests = async (status) => {
    try {
        const res = await client.query('SELECT * FROM passenger_trip WHERE status = $1', [status]);
        return res.rows;
    } catch (err) {
        console.error('Error fetching vehicles:', err);
        throw err;
    }
}

const insertRequest = async (passengerId, pickupLat, pickupLng, status) => {
    const sql = `INSERT INTO passenger_trip (passenger_id, pickup_lat, pickup_lng, status) VALUES ($1, $2, $3, $4) RETURNING *`;
    const res = await client.query(sql, [passengerId, pickupLat, pickupLng, status]);
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

module.exports = {
    getAllRequestsByPassengerId,
    getAllPendingRequests,
    insertRequest,
    updateRequestPickedUp,
    getPickupLocation,
    getAllOngoingTrips,
    updateTripStatus
};