const { startVehicleUpdater } = require('./vehicleUpdater');
const { startPassengerTripJobs } = require('./passengerTripUpdater');
const { startTripJobs } = require('./tripUpdater');
const cron = require('node-cron');
const userModel = require('../models/userModels');
const activityLogsModel = require('../models/activityLogsModel');

function startCronJobs(io) {
  //startVehicleUpdater(io);
  startPassengerTripJobs(io);
  startTripJobs(io);

  // Cleanup expired archived users daily at 2 AM
  cron.schedule('0 2 * * *', async () => {
    try {
      console.log('Running daily cleanup of expired archived users...');
      const deletedCount = await userModel.deleteExpiredArchivedUsers();
      if (deletedCount > 0) {
        await activityLogsModel.logActivity(
          'Cleanup',
          `Automatically deleted ${deletedCount} expired archived users (archived >30 days ago)`
        );
        console.log(`✓ Cleaned up ${deletedCount} expired archived users`);
      } else {
        console.log('✓ No expired archived users to clean up');
      }
    } catch (error) {
      console.error('Error during cleanup of expired archived users:', error);
    }
  });
  console.log('✓ Scheduled daily cleanup of expired archived users (runs at 2 AM)');
}

module.exports = { startCronJobs };