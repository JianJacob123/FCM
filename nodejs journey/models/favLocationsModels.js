const client = require('../config/db'); //db connection file

const getFavoriteLocationsByUserId = async (userId) => {
    const sql = `SELECT * FROM favorite_locations WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rows;
}

const addFavoriteLocation = async (userId, locationName) => {
    const sql = `INSERT INTO favorite_locations (passenger_id, location_name) 
                 VALUES ($1, $2) RETURNING *`;
    const res = await client.query(sql, [userId, locationName]);
    return res.rows[0];
}

module.exports = {
    getFavoriteLocationsByUserId,
    addFavoriteLocation
};