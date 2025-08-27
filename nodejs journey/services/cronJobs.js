const { startVehicleUpdater } = require('./vehicleUpdater');
const { startPassengerTripJobs } = require('./passengerTripUpdater');

function startCronJobs(io) {
  startVehicleUpdater(io);
  startPassengerTripJobs();
}

module.exports = { startCronJobs };