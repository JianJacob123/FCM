const userModel = require('../models/userModels');
const activityLogsModel = require('../models/activityLogsModel');

// Verify login credentials
const verifyLogin = async (req, res) => {
    const { username, password } = req.body;
    try {
        const user = await userModel.authLogin(username, password);
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }
        res.json({ message: 'Login successful', data: user });
        await activityLogsModel.logActivity('Login', `User ${username} logged in`);
    } catch (err) {
        console.error('Error during login:', err);
        res.status(500).json({ error: err.message });
    }
    
}


const getUserById = async (req, res) => {
    const userId = req.params.id;
    try {
        const user = await userModel.getUserById(userId);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json(user);
    } catch (err) {
        console.error('Error fetching user:', err);
        res.status(500).json({ error: err.message });
    }
}

// List all users
const listUsers = async (_req, res) => {
    try {
        const users = await userModel.listUsers();
        res.json({ success: true, data: users });
    } catch (err) {
        console.error('Error listing users:', err);
        res.status(500).json({ success: false, error: err.message });
    }
}

// Create user
const createUser = async (req, res) => {
    try {
        const required = ['full_name', 'user_role', 'username', 'user_pass'];
        for (const k of required) if (!req.body?.[k]) return res.status(400).json({ success: false, error: `${k} is required` });
        const created = await userModel.createUser(req.body);
        res.status(201).json({ success: true, id: created.user_id });
    } catch (err) {
        console.error('Error creating user:', err);
        res.status(500).json({ success: false, error: err.message });
    }
}

// Update user
const updateUser = async (req, res) => {
    try {
        await userModel.updateUser(req.params.id, req.body || {});
        res.json({ success: true });
    } catch (err) {
        console.error('Error updating user:', err);
        res.status(500).json({ success: false, error: err.message });
    }
}

// Delete user
const deleteUser = async (req, res) => {
    try {
        await userModel.deleteUser(req.params.id);
        res.json({ success: true });
    } catch (err) {
        console.error('Error deleting user:', err);
        res.status(500).json({ success: false, error: err.message });
    }
}

// Reveal password with admin verification
const revealPassword = async (req, res) => {
    try {
        // No admin verification
        const pass = await userModel.getUserPasswordPlain(req.params.id);
        if (pass === undefined) return res.status(404).json({ success: false, error: 'User not found' });
        res.json({ success: true, password: pass });
    } catch (err) {
        console.error('Error revealing password:', err);
        res.status(500).json({ success: false, error: err.message });
    }
}

module.exports = {
    getUserById,
    verifyLogin,
    listUsers,
    createUser,
    updateUser,
    deleteUser,
    revealPassword
};