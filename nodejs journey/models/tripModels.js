const client = require('../config/db'); //db connection file

const getActiveTripsByVehicle = async (vehicleId) => {
    const sql = `SELECT * FROM trips WHERE vehicle_id = $1 AND end_time IS NULL;`;
    const res = await client.query(sql, [vehicleId]);
    return res.rows[0];
}   

const insertTrip = async (vehicleId, startLat, startLng, status) => {
    const sql = `INSERT INTO trips (vehicle_id, start_time, start_lat, start_lng, status) VALUES ($1, NOW(), $2, $3, $4) RETURNING *;`;
    const res = await client.query(sql, [vehicleId, startLat, startLng, status]);
    return res.rows[0];
}

const endTrip = async (vehicleId, endLat, endLng) => {
    const sql = `UPDATE trips SET end_time = NOW(), end_lat = $1, end_lng = $2 WHERE vehicle_id = $3 AND end_time IS NULL RETURNING *;`;
    const res = await client.query(sql, [endLat, endLng, vehicleId]);
    return res.rows[0];
}

module.exports = {
    getActiveTripsByVehicle,
    insertTrip,
    endTrip
};