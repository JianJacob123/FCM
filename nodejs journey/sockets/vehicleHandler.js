// vehicleSocket.js
const vehicleModel = require('../models/vehicleModels');

const vehicleSocketHandler = (io) => {
  io.on("connection", (socket) => {
    console.log("Vehicle socket connected:", socket.id);

    // Listen for subscription (no auth required here)
    socket.on("subscribeVehicles", async () => {
      console.log(`📡 Socket ${socket.id} subscribed to vehicle updates`);

      socket.join("vehicleRoom");

      // Send initial snapshot
      const vehicles = await vehicleModel.getAllVehicles();
      socket.emit("vehicleUpdate", vehicles);
    });

    // Optional: unsubscribe
    socket.on("unsubscribeVehicles", () => {
      socket.leave("vehicleRoom");
      console.log(`Socket ${socket.id} left vehicleRoom`);
    });

    socket.on("disconnect", () => {
      console.log(`Vehicle socket disconnected: ${socket.id}`);
    });

    // === CONDUCTOR subscription ===
    socket.on("subscribeConductor", async (userId) => {
      console.log(`Socket ${socket.id} subscribed as conductor ${userId}`);

      socket.join(`conductor:${userId}`);

      // Send initial snapshot (only their assigned vehicle)
      const assignedVehicle = await vehicleModel.getVehicleByConductor(userId);
      socket.emit("vehicleUpdate", assignedVehicle);
    });

    socket.on("unsubscribeConductor", (userId) => {
      socket.leave(`conductor:${userId}`);
      console.log(`Socket ${socket.id} left conductor:${userId}`);
    });

    // Disconnect
    socket.on("disconnect", () => {
      console.log(`Vehicle socket disconnected: ${socket.id}`);
    });
    
  });
};

module.exports = vehicleSocketHandler;
