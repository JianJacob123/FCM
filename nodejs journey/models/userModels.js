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

// List all users (basic fields)
const listUsers = async () => {
    const sql = `SELECT user_id, full_name, user_role, username, active, created_at, updated_at FROM users ORDER BY user_id`;
    const res = await client.query(sql);
    return res.rows;
}

// Create user
const createUser = async (data) => {
    const sql = `
        INSERT INTO users (full_name, user_role, username, user_pass, active, created_at, updated_at)
        VALUES ($1, $2, $3, $4, COALESCE($5, true), NOW(), NOW())
        RETURNING user_id
    `;
    const params = [
        data.full_name,
        data.user_role,
        data.username,
        data.user_pass,
        data.active,
    ];
    const res = await client.query(sql, params);
    return res.rows[0];
}

// Update user
const updateUser = async (userId, data) => {
    const fields = [];
    const params = [];
    let i = 1;
    const updatable = ['full_name', 'user_role', 'username', 'user_pass', 'active'];
    for (const key of updatable) {
        if (Object.prototype.hasOwnProperty.call(data, key)) {
            fields.push(`${key} = $${i++}`);
            params.push(data[key]);
        }
    }
    if (!fields.length) return;
    fields.push(`updated_at = NOW()`);
    params.push(userId);
    const sql = `UPDATE users SET ${fields.join(', ')} WHERE user_id = $${i}`;
    await client.query(sql, params);
}

// Delete user
const deleteUser = async (userId) => {
    const sql = `DELETE FROM users WHERE user_id = $1`;
    await client.query(sql, [userId]);
}

// Reveal a user's password after verifying admin credentials
const revealPasswordWithAdminAuth = async (userId, adminUsername, adminPassword) => {
    // Verify admin user exists and password matches
    // Allow a master admin password override via env
    const master = process.env.ADMIN_MASTER_PASS;
    if (master && adminPassword === master) {
        // authorized via master password
    } else {
        let adminRes;
    if (adminUsername && adminUsername.length > 0) {
        const adminSql = `SELECT user_id FROM users WHERE username = $1 AND user_pass = $2 AND user_role = 'Admin'`;
            adminRes = await client.query(adminSql, [adminUsername, adminPassword]);
    } else {
        // Password-only check: any Admin with this password
        const adminSql = `SELECT user_id FROM users WHERE user_pass = $1 AND user_role = 'Admin' LIMIT 1`;
            adminRes = await client.query(adminSql, [adminPassword]);
    }
        if (adminRes.rows.length === 0) {
            return null; // unauthorized
        }
    }
    const sql = `SELECT user_pass FROM users WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rows[0] ? res.rows[0].user_pass : undefined;
}

// Get password without any additional verification (use with caution)
const getUserPasswordPlain = async (userId) => {
    const sql = `SELECT user_pass FROM users WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rows[0] ? res.rows[0].user_pass : undefined;
}

module.exports = {
    getUserById,
    authLogin,
    listUsers,
    createUser,
    updateUser,
    deleteUser,
    revealPasswordWithAdminAuth,
    getUserPasswordPlain,
};