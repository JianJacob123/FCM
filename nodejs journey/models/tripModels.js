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

// Get all trips for admin dashboard
const getAllTrips = async (limit = 50, offset = 0) => {
    const sql = `
        SELECT 
            t.trip_id,
            t.vehicle_id,
            CONCAT('Vehicle ', t.vehicle_id) as vehicle_number,
            t.start_time,
            t.end_time,
            t.start_lat,
            t.start_lng,
            t.end_lat,
            t.end_lng,
            t.status,
            t.total_passenger_accumulated
        FROM trips t
        ORDER BY t.start_time DESC
        LIMIT $1 OFFSET $2
    `;
    const res = await client.query(sql, [limit, offset]);
    return res.rows;
}

// Get total count of trips
const getTotalTripsCount = async () => {
    const sql = `SELECT COUNT(*) as total FROM trips`;
    const res = await client.query(sql);
    return res.rows[0].total;
}

// Get trips for a specific local date with timezone conversion
const getTripsForLocalDate = async (dateYmd, tz = 'Asia/Manila', limit = 1000, offset = 0) => {
    const sql = `
        SELECT 
            t.trip_id,
            t.vehicle_id,
            CONCAT('Vehicle ', t.vehicle_id) as vehicle_number,
            t.start_time,
            t.end_time,
            t.start_lat,
            t.start_lng,
            t.end_lat,
            t.end_lng,
            t.status,
            t.total_passenger_accumulated
        FROM trips t
        WHERE DATE((t.start_time AT TIME ZONE 'UTC') AT TIME ZONE $2) = $1
        ORDER BY t.start_time DESC
        LIMIT $3 OFFSET $4
    `;
    const res = await client.query(sql, [dateYmd, tz, limit, offset]);
    return res.rows;
}

// Get today's passenger count with time-based breakdown
const getTodayPassengerCount = async (startOfDay, endOfDay) => {
    const sql = `
        SELECT 
            COALESCE(SUM(total_passenger_accumulated), 0) as total_passengers,
            COALESCE(SUM(CASE 
                WHEN EXTRACT(HOUR FROM end_time) >= 4 AND EXTRACT(HOUR FROM end_time) < 12 
                THEN total_passenger_accumulated 
                ELSE 0 
            END), 0) as morning_passengers,
            COALESCE(SUM(CASE 
                WHEN EXTRACT(HOUR FROM end_time) >= 12 AND EXTRACT(HOUR FROM end_time) < 16 
                THEN total_passenger_accumulated 
                ELSE 0 
            END), 0) as midday_passengers,
            COALESCE(SUM(CASE 
                WHEN EXTRACT(HOUR FROM end_time) >= 16 AND EXTRACT(HOUR FROM end_time) <= 20 
                OR EXTRACT(HOUR FROM end_time) >= 21
                THEN total_passenger_accumulated 
                ELSE 0 
            END), 0) as evening_passengers,
            -- Debug: Show sample end_times for debugging
            ARRAY_AGG(DISTINCT EXTRACT(HOUR FROM end_time) ORDER BY EXTRACT(HOUR FROM end_time)) as sample_hours,
            COUNT(*) as total_trips
        FROM trips 
        WHERE start_time >= $1 AND start_time < $2
    `;
    const res = await client.query(sql, [startOfDay, endOfDay]);
    const row = res.rows[0];
    
    // Debug logging
    console.log('Today\'s trips debug:', {
        total_trips: row.total_trips,
        sample_hours: row.sample_hours,
        morning: row.morning_passengers,
        midday: row.midday_passengers,
        evening: row.evening_passengers
    });
    
    return {
        total_passengers: parseInt(row.total_passengers),
        morning_passengers: parseInt(row.morning_passengers),
        midday_passengers: parseInt(row.midday_passengers),
        evening_passengers: parseInt(row.evening_passengers),
        debug_info: {
            total_trips: row.total_trips,
            sample_hours: row.sample_hours
        }
    };
}

// Passenger count for a specific local date with timezone conversion
const getPassengerCountForLocalDate = async (dateYmd, tz = 'Asia/Manila') => {
    const sql = `
        SELECT 
            COALESCE(SUM(total_passenger_accumulated), 0) as total_passengers,
            COALESCE(SUM(CASE 
                WHEN EXTRACT(HOUR FROM ((end_time AT TIME ZONE 'UTC') AT TIME ZONE $2)) >= 4 
                 AND EXTRACT(HOUR FROM ((end_time AT TIME ZONE 'UTC') AT TIME ZONE $2)) < 12 
                THEN total_passenger_accumulated ELSE 0 END), 0) as morning_passengers,
            COALESCE(SUM(CASE 
                WHEN EXTRACT(HOUR FROM ((end_time AT TIME ZONE 'UTC') AT TIME ZONE $2)) >= 12 
                 AND EXTRACT(HOUR FROM ((end_time AT TIME ZONE 'UTC') AT TIME ZONE $2)) < 16 
                THEN total_passenger_accumulated ELSE 0 END), 0) as midday_passengers,
            COALESCE(SUM(CASE 
                WHEN EXTRACT(HOUR FROM ((end_time AT TIME ZONE 'UTC') AT TIME ZONE $2)) >= 16 
                 AND EXTRACT(HOUR FROM ((end_time AT TIME ZONE 'UTC') AT TIME ZONE $2)) <= 20 
                 OR EXTRACT(HOUR FROM ((end_time AT TIME ZONE 'UTC') AT TIME ZONE $2)) >= 21
                THEN total_passenger_accumulated ELSE 0 END), 0) as evening_passengers,
            COUNT(*) as total_trips
        FROM trips
        WHERE DATE(((start_time AT TIME ZONE 'UTC') AT TIME ZONE $2)) = $1
    `;
    const res = await client.query(sql, [dateYmd, tz]);
    const row = res.rows[0];
    return {
        total_passengers: parseInt(row.total_passengers),
        morning_passengers: parseInt(row.morning_passengers),
        midday_passengers: parseInt(row.midday_passengers),
        evening_passengers: parseInt(row.evening_passengers),
        debug_info: { total_trips: row.total_trips }
    };
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
    countActiveVehiclesByHour,
    getAllTrips,
    getTotalTripsCount,
    getTodayPassengerCount,
    getPassengerCountForLocalDate
};