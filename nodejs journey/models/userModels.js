const client = require('../config/db'); //db connection file
const bcrypt = require('bcryptjs');

// Helpers for password hashing/verification with backward compatibility
const isBcryptHash = (value) => typeof value === 'string' && value.startsWith('$2');
const hashPassword = async (plain) => {
  const salt = await bcrypt.genSalt(10);
  return await bcrypt.hash(plain, salt);
};
const verifyAgainstStored = async (plain, stored) => {
  if (!stored) return false;
  if (isBcryptHash(stored)) {
    try {
      return await bcrypt.compare(plain, stored);
    } catch {
      return false;
    }
  }
  // Backward-compat: plaintext match
  return plain === stored;
};

const authLogin = async (username, password) => {
    // Fetch by username, then verify with bcrypt/compat
    const sql = `SELECT user_id, full_name, user_role, user_pass FROM users WHERE username = $1 LIMIT 1`;
    const res = await client.query(sql, [username]);
    const row = res.rows[0];
    if (!row) return undefined;
    const ok = await verifyAgainstStored(password, row.user_pass);
    if (!ok) return undefined;
    return { user_id: row.user_id, full_name: row.full_name, user_role: row.user_role };
}

const getUserById = async (userId) => {
    const sql = `SELECT * FROM users WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rows[0];
}

// List all users (basic fields) - excludes archived
const listUsers = async () => {
    const sql = `SELECT user_id, full_name, user_role, username, active, created_at, updated_at FROM users WHERE archived IS NOT TRUE ORDER BY user_id`;
    const res = await client.query(sql);
    return res.rows;
}

// List archived users
const listArchivedUsers = async () => {
    const sql = `SELECT user_id, full_name, user_role, username, active, created_at, updated_at, archived_at FROM users WHERE archived = true ORDER BY archived_at DESC, user_id`;
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
    // Ensure password is hashed on create
    const hashed = isBcryptHash(data.user_pass)
      ? data.user_pass
      : await hashPassword(data.user_pass);
    const params = [
        data.full_name,
        data.user_role,
        data.username,
        hashed,
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
            if (key === 'user_pass' && data[key]) {
                const hashed = isBcryptHash(data[key])
                  ? data[key]
                  : await hashPassword(data[key]);
                fields.push(`${key} = $${i++}`);
                params.push(hashed);
            } else {
                fields.push(`${key} = $${i++}`);
                params.push(data[key]);
            }
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

// Archive user
const archiveUser = async (userId) => {
    const sql = `UPDATE users SET archived = true, archived_at = NOW(), updated_at = NOW() WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rowCount > 0;
}

// Restore archived user
const restoreUser = async (userId) => {
    const sql = `UPDATE users SET archived = false, archived_at = NULL, updated_at = NOW() WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    return res.rowCount > 0;
}

// Permanently delete users archived more than 30 days ago
const deleteExpiredArchivedUsers = async () => {
    const sql = `DELETE FROM users WHERE archived = true AND archived_at < NOW() - INTERVAL '30 days'`;
    const res = await client.query(sql);
    return res.rowCount;
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
            const adminSql = `SELECT user_id, user_pass FROM users WHERE username = $1 AND user_role = 'admin' LIMIT 1`;
            const r = await client.query(adminSql, [adminUsername]);
            const ok = r.rows[0] ? await verifyAgainstStored(adminPassword, r.rows[0].user_pass) : false;
            adminRes = { rows: ok ? [r.rows[0]] : [] };
        } else {
            // Password-only check: any admin with this password (scan limited set)
            const adminSql = `SELECT user_id, user_pass FROM users WHERE user_role = 'admin' LIMIT 10`;
            const r = await client.query(adminSql, []);
            let okRow = null;
            for (const row of r.rows) {
                if (await verifyAgainstStored(adminPassword, row.user_pass)) { okRow = row; break; }
            }
            adminRes = { rows: okRow ? [okRow] : [] };
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

// Verify if the provided password matches the user's stored password
const verifyPassword = async (userId, password) => {
    const sql = `SELECT user_pass FROM users WHERE user_id = $1`;
    const res = await client.query(sql, [userId]);
    if (!res.rows[0]) {
        return false; // User not found
    }
    const storedPassword = res.rows[0].user_pass;
    return await verifyAgainstStored(password, storedPassword);
}

module.exports = {
    getUserById,
    authLogin,
    listUsers,
    listArchivedUsers,
    createUser,
    updateUser,
    deleteUser,
    archiveUser,
    restoreUser,
    deleteExpiredArchivedUsers,
    revealPasswordWithAdminAuth,
    getUserPasswordPlain,
    verifyPassword,
};