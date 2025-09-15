const { startVehicleUpdater } = require('./vehicleUpdater');
const { startPassengerTripJobs } = require('./passengerTripUpdater');
const { startTripJobs } = require('./tripUpdater')

function startCronJobs(io) {
  startVehicleUpdater(io);
  startPassengerTripJobs();
  startTripJobs();
}

module.exports = { startCronJobs };