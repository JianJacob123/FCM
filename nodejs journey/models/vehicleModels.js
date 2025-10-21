const client = require('../config/db'); //db connection file

/*async function getIoTData() {
    const response = await axios.get('http://localhost:4000/iot-data');
    return response.data;
}*/

const getAllVehicles = async () => {
    try {
        const res = await client.query(`
       SELECT 
  v.vehicle_id AS vehicle_id,
  ST_X(v.current_location) AS lng,
  ST_Y(v.current_location) AS lat,
  v.current_passenger_count,
  v.total_passengers,
  r.route_name,
  r.route_id,

  -- Route progress as percentage (cast to numeric before rounding)
  ROUND(
    (ST_LineLocatePoint(r.route_geom, ST_ClosestPoint(r.route_geom, v.current_location)) * 100)::numeric,
    2
  ) AS route_progress_percent,

  -- Remaining route geometry as GeoJSON
  ST_AsGeoJSON(
    ST_LineSubstring(
      r.route_geom,
      ST_LineLocatePoint(r.route_geom, ST_ClosestPoint(r.route_geom, v.current_location)),
      1
    ),
    6
  ) AS remaining_route_polyline,

  -- ETA based on current progress and route_duration
  NOW() + r.route_duration * (1 - ST_LineLocatePoint(r.route_geom, ST_ClosestPoint(r.route_geom, v.current_location))) AS eta,

  -- Distance (in meters) from current location to the nearest point on the route
  ST_DistanceSphere(
    v.current_location,
    ST_ClosestPoint(r.route_geom, v.current_location)
  ) AS distance_from_route_meters,

  -- Off-route detection (TRUE if vehicle is farther than 30m from the route)
  CASE
    WHEN ST_DistanceSphere(v.current_location, ST_ClosestPoint(r.route_geom, v.current_location)) > 30 THEN TRUE
    ELSE FALSE
  END AS is_off_route

FROM vehicles v
INNER JOIN routes r ON v.route_id = r.route_id;


            `);
        return res.rows;
    } catch (err) {
        console.error('Error fetching vehicles:', err);
        throw err;
    }
}

const getVehicleById = async (vehicleId) => {
    const sql = `SELECT * FROM vehicles WHERE vehicle_id = $1`;
    const res = await client.query(sql, [vehicleId]);
    return res.rows[0];
}


const updateVehicleCoordinates = async (vehicleId, latitude, longitude, currentPassengerCount, addedPassengers) => {
    const sql = `UPDATE vehicles SET lat = $1, lng = $2,  current_location = ST_SetSRID(ST_MakePoint($2, $1), 4326), current_passenger_count = $3, total_passengers = total_passengers + $4  WHERE vehicle_id = $5;`
    await client.query(sql, [latitude, longitude, currentPassengerCount, addedPassengers, vehicleId]);
}

// For extracting the added passengers to the current_passenger_count
const getCurrentPassengerCount = async (vehicleId) => {
    const sql = 'SELECT current_passenger_count FROM vehicles WHERE vehicle_id = $1;';
    const res = await client.query(sql, [vehicleId]);
    return res.rows.length ? res.rows[0].current_passenger_count : 0;
}

const updateRouteId = async (vehicleId, routeId) => {
    const sql = `UPDATE vehicles SET route_id = $1 WHERE vehicle_id = $2;`;
    await client.query(sql, [routeId, vehicleId]);
}

const getVehicleByConductor = async (userId) => {
    try {
        const res = await client.query(`
            SELECT 
              v.vehicle_id::int,
              ST_X(v.current_location) AS lng,
              ST_Y(v.current_location) AS lat,
              v.current_passenger_count,
              v.total_passengers,
              r.route_name,
              r.route_id,

              -- Route progress as percentage (cast to numeric before rounding)
  ROUND(
    (ST_LineLocatePoint(r.route_geom, ST_ClosestPoint(r.route_geom, v.current_location)) * 100)::numeric,
    2
  ) AS route_progress_percent,


              ST_AsGeoJSON(
                ST_LineSubstring(
                  r.route_geom,
                  ST_LineLocatePoint(r.route_geom, ST_ClosestPoint(r.route_geom, v.current_location)),
                  1
                ),
                6
              ) AS remaining_route_polyline,

    -- ETA based on current progress and route_duration
  NOW() + r.route_duration * (1 - ST_LineLocatePoint(r.route_geom, ST_ClosestPoint(r.route_geom, v.current_location))) AS eta,

  -- Distance (in meters) from current location to the nearest point on the route
  ST_DistanceSphere(
    v.current_location,
    ST_ClosestPoint(r.route_geom, v.current_location)
  ) AS distance_from_route_meters,

  -- Off-route detection (TRUE if vehicle is farther than 30m from the route)
  CASE
    WHEN ST_DistanceSphere(v.current_location, ST_ClosestPoint(r.route_geom, v.current_location)) > 30 THEN TRUE
    ELSE FALSE
  END AS is_off_route

            FROM vehicle_assignment va
            INNER JOIN vehicles v ON va.vehicle_id = v.vehicle_id
            INNER JOIN routes r ON v.route_id = r.route_id
            WHERE va.conductor_id = $1 OR va.driver_id = $1
        `, [userId]);

        return res.rows;
    } catch (err) {
        console.error('Error fetching vehicle for conductor:', err);
        throw err;
    }
}

const getConductorIdByVehicle = async (vehicleId) => {
    try {
        const sql = `
            SELECT user_id 
            FROM vehicle_assignment
            WHERE vehicle_id = $1
            LIMIT 1;
        `;
        const res = await client.query(sql, [vehicleId]);
        return res.rows.length ? res.rows[0].user_id : null;
    } catch (err) {
        console.error('Error fetching conductor by vehicle:', err);
        throw err;
    }
};

// Get daily passenger analytics for dashboard
const getDailyPassengerAnalytics = async () => {
    try {
        const res = await client.query(`
            SELECT 
                -- Total current passengers across all vehicles
                COALESCE(SUM(v.current_passenger_count), 0) as total_current_passengers,
                
                -- Total passengers served today
                COALESCE(SUM(v.total_passengers), 0) as total_passengers_served,
                
                -- Morning passengers (4 AM - 10 AM)
                COALESCE(SUM(CASE 
                    WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 6 AND 11 
                    THEN v.current_passenger_count 
                    ELSE 0 
                END), 0) as morning_passengers,
                
                -- Midday passengers (10 AM - 5 PM)
                COALESCE(SUM(CASE 
                    WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 12 AND 17 
                    THEN v.current_passenger_count 
                    ELSE 0 
                END), 0) as midday_passengers,
                
                -- Evening passengers (5 PM - 8 PM)
                COALESCE(SUM(CASE 
                    WHEN EXTRACT(HOUR FROM NOW()) BETWEEN 18 AND 23 
                    OR EXTRACT(HOUR FROM NOW()) BETWEEN 0 AND 5
                    THEN v.current_passenger_count 
                    ELSE 0 
                END), 0) as evening_passengers,
                
                -- Count of active vehicles
                COUNT(v.vehicle_id) as active_vehicles
                
            FROM vehicles v
            WHERE v.current_passenger_count > 0
        `);
        
        const analytics = res.rows[0];
        
        // Calculate percentages for the donut chart
        const total = analytics.total_current_passengers;
        const morningPct = total > 0 ? (analytics.morning_passengers / total * 100).toFixed(1) : 0;
        const middayPct = total > 0 ? (analytics.midday_passengers / total * 100).toFixed(1) : 0;
        const eveningPct = total > 0 ? (analytics.evening_passengers / total * 100).toFixed(1) : 0;
        
        return {
            total_passengers: total,
            total_served: analytics.total_passengers_served,
            active_vehicles: analytics.active_vehicles,
            time_distribution: {
                morning: {
                    count: analytics.morning_passengers,
                    percentage: parseFloat(morningPct)
                },
                midday: {
                    count: analytics.midday_passengers,
                    percentage: parseFloat(middayPct)
                },
                evening: {
                    count: analytics.evening_passengers,
                    percentage: parseFloat(eveningPct)
                }
            }
        };
    } catch (err) {
        console.error('Error fetching daily passenger analytics:', err);
        throw err;
    }
};

// Get average trip duration per vehicle for the day
const getAverageTripDurationPerVehicle = async () => {
    try {
        const res = await client.query(`
            SELECT 
                v.vehicle_id,
                r.route_name,
                COALESCE(AVG(EXTRACT(EPOCH FROM (t.end_time - t.start_time))/60), 0) as avg_duration_minutes,
                COUNT(t.trip_id) as total_trips,
                COALESCE(SUM(EXTRACT(EPOCH FROM (t.end_time - t.start_time))/60), 0) as total_duration_minutes
            FROM vehicles v
            LEFT JOIN routes r ON v.route_id = r.route_id
            LEFT JOIN trips t ON v.vehicle_id = t.vehicle_id 
                AND DATE(t.start_time) = CURRENT_DATE
                AND t.status = 'completed'
            GROUP BY v.vehicle_id, r.route_name
            ORDER BY v.vehicle_id
        `);
        
        const analytics = res.rows.map(row => ({
            vehicle_id: row.vehicle_id,
            route_name: row.route_name,
            avg_duration_minutes: parseFloat(row.avg_duration_minutes),
            total_trips: parseInt(row.total_trips),
            total_duration_minutes: parseFloat(row.total_duration_minutes)
        }));
        
        // Calculate overall average
        const totalTrips = analytics.reduce((sum, v) => sum + v.total_trips, 0);
        const totalDuration = analytics.reduce((sum, v) => sum + v.total_duration_minutes, 0);
        const overallAverage = totalTrips > 0 ? totalDuration / totalTrips : 0;
        
        return {
            vehicles: analytics,
            overall_average_minutes: overallAverage,
            total_vehicles: analytics.length,
            total_trips: totalTrips
        };
    } catch (err) {
        console.error('Error fetching average trip duration per vehicle:', err);
        throw err;
    }
};

const createVehicle = async (vehicleId, plateNumber) => {
    try {
        const res = await client.query(`
            INSERT INTO vehicles (vehicle_id, plate_number, current_location, current_passenger_count, total_passengers, route_id)
            VALUES ($1, $2, ST_GeomFromText('POINT(0 0)', 4326), 0, 0, NULL)
            RETURNING *
        `, [vehicleId, plateNumber]);
        return res.rows[0];
    } catch (error) {
        console.error('Error creating vehicle:', error);
        throw error;
    }
};

const updateVehiclePlateNumber = async (vehicleId, plateNumber) => {
    try {
        const res = await client.query(`
            UPDATE vehicles 
            SET plate_number = $2
            WHERE vehicle_id = $1
            RETURNING *
        `, [vehicleId, plateNumber]);
        return res.rows[0];
    } catch (error) {
        console.error('Error updating vehicle plate number:', error);
        throw error;
    }
};

module.exports = {
    getAllVehicles,
    getVehicleById,
    updateVehicleCoordinates,
    getCurrentPassengerCount,
    updateRouteId,
    getVehicleByConductor,
    getConductorIdByVehicle,
    getDailyPassengerAnalytics,
    getAverageTripDurationPerVehicle,
    createVehicle,
    updateVehiclePlateNumber
};