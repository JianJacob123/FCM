const client = require('../config/db'); //db connection file

const getToRouteId = async (toRouteId) => {
    const sql = `SELECT to_route_id FROM route_mapping WHERE from_route_id = $1;`;
    const res = await client.query(sql, [toRouteId]);
    return res.rows[0]?.to_route_id;
}

module.exports = {
    getToRouteId,
}