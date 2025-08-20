const client = require('../config/db'); //db connection file

const getRouteById = async (routeId) => {
    const sql = `SELECT * FROM routes WHERE id = $1;`;
    const res = await client.query(sql, [routeId]);
    return res.rows[0];
}

module.exports = {
    getRouteById 
};