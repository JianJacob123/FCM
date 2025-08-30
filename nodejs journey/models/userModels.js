const client = require('../config/db'); //db connection file

const authLogin = async (username, password) => {
    const sql = `SELECT user_id, full_name, user_role FROM users WHERE username = $1 AND user_pass = $2`;
    const res = await client.query(sql, [username, password]);
    return res.rows[0];
}

const getUserById = async (userId) => {
    const sql = `SELECT * FROM users WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rows[0];
}

module.exports = {
    getUserById,
    authLogin
};