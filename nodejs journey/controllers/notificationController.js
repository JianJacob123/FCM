const notificationModels = require('../models/notificationModels');

const getNotifications = async (req, res) => {
    try {
        const notifications = await notificationModels.getAllNotifications();
        res.json(notifications);
    } catch (err) {
        console.error('Error fetching notifications:', err);
        res.status(500).json({ error: err.message });
    }
}

const createNotification = async (req, res) => {
    const { notif_title, notif_type, content, notif_date } = req.body;
    try {
        await notificationModels.createAllNotifications(notif_title, notif_type, content, notif_date);
        res.status(201).json({ message: 'Notification created successfully' });
    } catch (err) {
        console.error('Error creating notification:', err);
        res.status(500).json({ error: err.message });
    }
}

module.exports = {
    getNotifications,
    createNotification
};

