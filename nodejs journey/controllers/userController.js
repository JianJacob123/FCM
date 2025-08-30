const userModel = require('../models/userModels');

const verifyLogin = async (req, res) => {
    const { username, password } = req.body;
    try {
        const user = await userModel.authLogin(username, password);
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }
        res.json({ message: 'Login successful', data: user });
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

module.exports = {
    getUserById,
    verifyLogin
};