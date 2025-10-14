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


module.exports = {
    getAllVehicles,
    getVehicleById,
    updateVehicleCoordinates,
    getCurrentPassengerCount,
    updateRouteId,
    getVehicleByConductor,
    getConductorIdByVehicle
};