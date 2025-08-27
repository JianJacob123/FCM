const client = require('../config/db'); //db connection file


const getUserById = async (userId) => {
    const sql = `SELECT * FROM users WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rows[0];
}

module.exports = {
    getUserById 
};