const client = require('../config/db'); //db connection file

const logActivity = async (activityType, description) => {
    const sql = `INSERT INTO activity_logs (activity_type, description, created_at) VALUES ($1, $2, NOW()) RETURNING *`;
    const res = await client.query(sql, [activityType, description]);
    return res.rows[0];
}

const getAllActivityLogs = async () => {
    const sql = `SELECT * FROM activity_logs ORDER BY created_at DESC`;
    const res = await client.query(sql);
    return res.rows;
}

module.exports = {
    logActivity,
    getAllActivityLogs
};