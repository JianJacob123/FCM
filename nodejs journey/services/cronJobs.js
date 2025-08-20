const { startVehicleUpdater } = require('./vehicleUpdater');
const { startPassengerTripJobs } = require('./passengerTripUpdater');

function startCronJobs() {
  startVehicleUpdater();
  startPassengerTripJobs();
}

module.exports = { startCronJobs };