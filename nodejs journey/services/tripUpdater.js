const cron = require('node-cron');
const tripController = require('../controllers/tripController');

function startTripJobs (io) {
    cron.schedule('*/30 * * * * *', async () => {
        try {
            await tripController.startTripIfInGeofence(io);
            console.log('[CRON] Trip Checks Done')
        } catch (err) {
            console.error('[CRON] Error on checking Trips', err)
        }
    })
}

module.exports = {
    startTripJobs
}