const client = require('../config/db'); //db connection file

const getActiveTripsByVehicle = async (vehicleId) => {
    const sql = `SELECT * FROM trips WHERE vehicle_id = $1 AND end_time IS NULL;`;
    const res = await client.query(sql, [vehicleId]);
    return res.rows;
}   

const insertTrip = async (vehicleId, startLat, startLng, status) => {
    const sql = `INSERT INTO trips (vehicle_id, start_time, start_lat, start_lng, status) VALUES ($1, NOW(), $2, $3, $4) RETURNING *;`;
    const res = await client.query(sql, [vehicleId, startLat, startLng, status]);
    return res.rows[0];
}

const endTrip = async (vehicleId, endLat, endLng, status) => {
    const sql = `UPDATE trips SET end_time = NOW(), end_lat = $1, end_lng = $2, status = $3 WHERE vehicle_id = $4 AND end_time IS NULL RETURNING *;`;
    const res = await client.query(sql, [endLat, endLng, status, vehicleId]);
    return res.rows[0];
}

const fetchGeofenceState = async (vehicleId) => {
    const sql = `SELECT * FROM vehicle_geofence_state WHERE vehicle_id = $1`
    const res = await client.query(sql, [vehicleId])
    return res.rows[0];
}

const updateGeofenceState = async (vehicleId, state) => {
    const sql = `UPDATE vehicle_geofence_state SET at_start = $1, at_end = $2, last_updated = NOW() WHERE vehicle_id = $3`
    const values = [state.at_start, state.at_end, vehicleId]
    await client.query(sql, values);
}

//Get Trips Logic
const getVehicleByConductorId = async (conductorId) => {
    const sql = `SELECT vehicle_id FROM vehicle_assignment WHERE conductor_id = $1 or driver_id = $1;`;
    const res = await client.query(sql, [conductorId]);
    return res.rows[0];
}

const getTripCountByVehicleId = async (vehicleId) => {
    const sql = `SELECT COUNT(trip_id) as total_trips FROM trips WHERE vehicle_id = $1;`;
    const res = await client.query(sql, [vehicleId]);
    return res.rows[0].total_trips;
}

const getRecentTripsByVehicleId = async (vehicleId) => {
    const sql = `SELECT * FROM trips WHERE vehicle_id = $1 AND status = 'completed' ORDER BY end_time DESC LIMIT 3;`;
    const res = await client.query(sql, [vehicleId]);
    return res.rows;
}

// Count trips per vehicle for a specific date (00:00-23:59)
const countTripsPerVehicleForDate = async (dateYmd) => {
    const sql = `
        SELECT vehicle_id, COUNT(*)::int AS trips
        FROM trips
        WHERE status = 'completed'
          AND DATE(start_time) = $1
        GROUP BY vehicle_id
        ORDER BY vehicle_id
    `;
    const res = await client.query(sql, [dateYmd]);
    return res.rows; // [{vehicle_id, trips}]
}

// Count distinct active vehicles per hour of day for a date
const countActiveVehiclesByHour = async (dateYmd) => {
    const sql = `
      SELECT EXTRACT(HOUR FROM start_time)::int AS hour, COUNT(DISTINCT vehicle_id)::int AS buses
      FROM trips
      WHERE DATE(start_time) = $1
      GROUP BY 1
    `;
    const res = await client.query(sql, [dateYmd]);
    return res.rows; // [{hour, buses}]
}

module.exports = {
    getActiveTripsByVehicle,
    insertTrip,
    endTrip,
    fetchGeofenceState,
    updateGeofenceState,
    getVehicleByConductorId,
    getTripCountByVehicleId,
    getRecentTripsByVehicleId,
    countTripsPerVehicleForDate,
    countActiveVehiclesByHour
};