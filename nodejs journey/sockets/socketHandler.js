const userModel = require('../models/userModels');

const socketHandler = (io) => {
  io.on("connection", async (socket) => {
    console.log("⚡ A client connected:", socket.id);

    // --- STEP 1: Get userId from handshake (query for now) ---
    const { userId } = socket.handshake.query;

    if (!userId) {
      socket.emit("authError", "Missing userId");
      socket.disconnect();
      return;
    }

    try {
      // --- STEP 2: Look up the user in Postgres ---
      const user = await userModel.getUserById(userId);

      if (!user) {
        socket.emit("authError", "User not found");
        socket.disconnect();
        return;
      }

      // --- STEP 3: Attach user info to the socket ---
      socket.user = user;

      // --- STEP 4: Put all users in the same chatroom (for now) ---
      socket.join("chatroom");

      socket.emit("authSuccess", `Welcome ${user.name} (${user.role})`);
      console.log(`✅ ${user.name} (${user.role}) joined the chatroom`);

      // --- STEP 5: Message handling ---
      socket.on("sendMessage", (msg) => {
        console.log(`💬 ${user.name}: ${msg}`);
        io.to("chatroom").emit("receiveMessage", {
          sender: user.name,
          role: user.role,
          message: msg,
          timestamp: new Date(),
        });
      });


      // --- STEP 6: Handle disconnect ---
      socket.on("disconnect", () => {
        console.log(`❌ ${user.name} disconnected`);
      });
    } catch (err) {
      console.error("Auth error:", err.message);
      socket.emit("authError", "DB error");
      socket.disconnect();
    }
  });
};

module.exports = socketHandler;