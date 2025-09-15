const cron = require('node-cron');
const vehicleController = require('../controllers/vehicleController');


function startVehicleUpdater(io) {
  // run every 30 seconds
  cron.schedule('*/30 * * * * *', async () => {
    try {
      await vehicleController.updateCoordinatesLogic(io);

      const vehicles = await vehicleController.getVehiclesDirect(); // make a direct fn that doesn't rely on req/res
      
      // Broadcast to all sockets subscribed
      io.to("vehicleRoom").emit("vehicleUpdate", vehicles);

      console.log('Vehicle coordinates updated');
    } catch (error) {
      console.error('Error updating vehicle coordinates:', error);
    }
  });
}

module.exports = {
  startVehicleUpdater
};

//Old Code

/*function startVehicleUpdater() {
  setInterval(async () => {
    try {
      await vehicleController.updateCoordinatesLogic();
      console.log('Vehicle coordinates updated');
    } catch (error) {
      console.error('Error updating vehicle coordinates:', error);
    }
  }, 30000); // every 30 seconds
}
module.exports = {
  startVehicleUpdater
};*/
