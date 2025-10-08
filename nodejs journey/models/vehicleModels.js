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
  NOW() + r.route_duration * (1 - ST_LineLocatePoint(r.route_geom, ST_ClosestPoint(r.route_geom, v.current_location))) AS eta

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


const updateVehicleCoordinates = async (vehicleId, latitude, longitude) => {
    const sql = `UPDATE vehicles SET lat = $1, lng = $2,  current_location = ST_SetSRID(ST_MakePoint($2, $1), 4326)  WHERE vehicle_id = $3;`
    await client.query(sql, [latitude, longitude, vehicleId]);
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
              ST_AsGeoJSON(
                ST_LineSubstring(
                  r.route_geom,
                  ST_LineLocatePoint(r.route_geom, ST_ClosestPoint(r.route_geom, v.current_location)),
                  1
                ),
                6
              ) AS remaining_route_polyline
            FROM vehicle_assignment va
            INNER JOIN vehicles v ON va.vehicle_id = v.vehicle_id
            INNER JOIN routes r ON v.route_id = r.route_id
            WHERE va.user_id = $1
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
    updateRouteId,
    getVehicleByConductor,
    getConductorIdByVehicle
};