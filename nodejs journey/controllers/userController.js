const userModel = require('../models/userModels');

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

module.exports = {
    getUserById
};