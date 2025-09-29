const socketHandler = (io) => {
  io.on("connection", (socket) => {
    console.log("Trip socket connected:", socket.id);

    // === Passenger subscribes to their trip updates ===
    socket.on("subscribeTrip", (passengerId) => {
      if (!passengerId) {
        console.warn(`Socket ${socket.id} tried to subscribe without passengerId`);
        return;
      }
      socket.join(`trip_${passengerId}`);
      console.log(`Passenger ${passengerId} subscribed to trip room`);
      socket.emit("tripSubscribed", { message: "Subscribed to trip updates" });
    });

    // === (Optional) Unsubscribe ===
    socket.on("unsubscribeTrip", (passengerId) => {
      socket.leave(`trip_${passengerId}`);
      console.log(`Passenger ${passengerId} unsubscribed from trip room`);
    });

    // === Disconnect ===
    socket.on("disconnect", () => {
      console.log("Trip socket disconnected:", socket.id);
    });
  });
};

module.exports = socketHandler;