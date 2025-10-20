const express = require('express');
const activityLogsController = require('../controllers/activityLogsController');
const router = express.Router();

// Route to get all activity logs
router.get('/fetchActivityLogs', activityLogsController.listActivityLogs);

module.exports = router;