const notificationModels = require('../models/notificationModels');

const getNotifications = async (req, res) => {
  const { recipient } = req.query; // Get recipient from query parameters
    try {
        const notifications = await notificationModels.getAllNotifications(recipient);
        res.json(notifications);
    } catch (err) {
        console.error('Error fetching notifications:', err);
        res.status(500).json({ error: err.message });
    }
}

const createNotification = async (notif_title, notif_type, content, notif_date) => { //FOR automated system notifs
  try {
    await notificationModels.createAllNotifications(
      notif_title,
      notif_type,
      content,
      notif_date
    );
    return { success: true, message: "Notification created successfully" };
  } catch (err) {
    console.error("Error creating notification:", err);
    return { success: false, error: err.message };
  }
};


// For Admin
const createPushNotification = async (req, res, io) => {
  const { notif_title, notif_type, content, notif_date, notif_recipient } = req.body;
  try {
    // Save notification in DB and return it
    const notification = await notificationModels.createAllNotifications(
      notif_title,
      notif_type,
      content,
      notif_date,
      notif_recipient
    );

    // Send API response
    res.status(201).json({
      message: "Notification created successfully",
      notification,
    });

    // Emit real-time notif to all users except admin
    io.of("/notifications").to("usersRoom").emit("newNotification", notification);

  } catch (err) {
    console.error("Error creating notification:", err);
    res.status(500).json({ error: err.message });
  }
};


module.exports = {
    getNotifications,
    createNotification,
    createPushNotification
};

