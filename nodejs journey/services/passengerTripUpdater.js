// cronJobs.js
const cron = require('node-cron');
const passengerTripController = require('../controllers/passengerTripController');

function startPassengerTripJobs() {
  // Check for vehicles near pickup every 30 seconds
  cron.schedule('*/30 * * * * *', async () => {
    try {
      await passengerTripController.checkVehicleNearPickUp();
      console.log('[CRON] Pickup proximity check done');
    } catch (err) {
      console.error('[CRON] Error in isVehicleNearPickUp:', err);
    }
  });

  // Monitor dropoffs every 1 minute
  cron.schedule('*/1 * * * *', async () => {
    try {
      await passengerTripController.checkDropoffs();
      console.log('[CRON] Dropoff check done');
    } catch (err) {
      console.error('[CRON] Error in monitorDropoffs:', err);
    }
  });
}

module.exports = {
  startPassengerTripJobs,
};
