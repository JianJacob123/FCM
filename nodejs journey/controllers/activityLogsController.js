const activityLogsModel = require('../models/activityLogsModel');

// List all activity logs
const listActivityLogs = async (req, res) => {
    try {
        const logs = await activityLogsModel.getAllActivityLogs();
        res.json(logs);
    } catch (err) {
        console.error('Error listing activity logs:', err);
        res.status(500).json({ success: false, error: err.message });
    }
}

module.exports = {
    listActivityLogs
};