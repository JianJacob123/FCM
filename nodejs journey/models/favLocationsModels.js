const client = require('../config/db'); //db connection file

const getFavoriteLocationsByUserId = async (userId) => {
    const sql = `SELECT * FROM favorite_locations WHERE passenger_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rows;
}

const addFavoriteLocation = async (userId, locationName, lat, lng) => {
    const sql = `INSERT INTO favorite_locations (passenger_id, location_name, lat, lng) 
                 VALUES ($1, $2, $3, $4) RETURNING *`;
    const res = await client.query(sql, [userId, locationName, lat, lng]);
    return res.rows[0];
}

module.exports = {
    getFavoriteLocationsByUserId,
    addFavoriteLocation
};