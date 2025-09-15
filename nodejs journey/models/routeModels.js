const client = require('../config/db'); //db connection file

async function updateRouteGeom(routeId, geometry) {
  const query = `
    UPDATE routes
    SET route_geom = ST_SetSRID(ST_GeomFromGeoJSON($1), 4326)
    WHERE route_id = $2
    RETURNING route_id, ST_AsText(route_geom) as geom;
  `;

  const values = [JSON.stringify(geometry), routeId];
  const result = await client.query(query, values);
  return result.rows[0];
}



const getRouteById = async (routeId) => {
    const sql = `SELECT * FROM routes WHERE route_id = $1;`;
    const res = await client.query(sql, [routeId]);
    return res.rows[0];
}

module.exports = {
    getRouteById,
    updateRouteGeom
};