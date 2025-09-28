const { startVehicleUpdater } = require('./vehicleUpdater');
const { startPassengerTripJobs } = require('./passengerTripUpdater');
const { startTripJobs } = require('./tripUpdater')

function startCronJobs(io) {
  //startVehicleUpdater(io);
  startPassengerTripJobs(io);
  startTripJobs(io);
}

module.exports = { startCronJobs };