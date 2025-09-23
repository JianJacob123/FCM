const client = require('../config/db'); //db connection file

const getAllNotifications = async (recipient) => {
  try {
    const res = await client.query(
      `SELECT * 
       FROM notifications 
       WHERE notif_recipient ILIKE $1 
       ORDER BY notif_date DESC`,
      [`%${recipient}%`]
    );
    return res.rows;
  } catch (err) {
    console.error('Error fetching notifications:', err);
    throw err;
  }
};


const createAllNotifications = async (notif_title, notif_type, content, notif_date, notif_recipient) => {
    const sql = `INSERT INTO notifications (notif_title, notif_type, content, notif_date, notif_recipient) VALUES ($1, $2, $3, $4, $5)`;
    const res = await client.query(sql, [notif_title, notif_type, content, notif_date, notif_recipient]);
    return res.rows;
}

module.exports = {
    getAllNotifications,
    createAllNotifications
};