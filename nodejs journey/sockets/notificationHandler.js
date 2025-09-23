// sockets/notificationHandler.js
module.exports = (io) => {
  io.on("connection", (socket) => {
    console.log("Notification client connected:", socket.id);

    // === User Notifications ===
    socket.on("subscribeNotifications", (userId) => {
      if (!userId) {
        console.warn(`Socket ${socket.id} tried to subscribe without userId`);
        return;
      }
      socket.join(`user_${userId}`);
       socket.join("usersRoom");
      console.log(`User ${userId} subscribed to notifications`);
    });

    // === Admin Notifications ===
    socket.on("subscribeAdminNotifications", () => {
      socket.join("adminRoom");
      console.log(`Admin ${socket.id} subscribed to admin room`);
      socket.emit("adminSubscribed", { message: "Subscribed to admin room" });
    });

    socket.on("unsubscribeAdminNotifications", () => {
      socket.leave("adminRoom");
      console.log(`Admin ${socket.id} unsubscribed from admin room`);
    });

    // === Disconnect ===
    socket.on("disconnect", () => {
      console.log("Notification client disconnected:", socket.id);
    });
  });
};
