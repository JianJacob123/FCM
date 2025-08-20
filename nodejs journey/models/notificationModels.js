const client = require('../config/db'); //db connection file

const getAllNotifications = async () => {
    try {
        const res = await client.query('SELECT * FROM notifications');
        return res.rows;
    } catch (err) {
        console.error('Error fetching notifications:', err);
        throw err;
    }
}

const createAllNotifications = async (notif_title, notif_type, content, notif_date) => {
    const sql = `INSERT INTO notifications (notif_title, notif_type, content, notif_date) VALUES ($1, $2, $3, $4)`;
    const res = await client.query(sql, [notif_title, notif_type, content, notif_date]);
}

module.exports = {
    getAllNotifications,
    createAllNotifications
};