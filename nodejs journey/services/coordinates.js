const WebSocket = require("ws");
const vehicleController = require("../controllers/vehicleController");

let socket;

function connectIoTData(io) {
  socket = new WebSocket("wss://transiteye-api.net/socket/client");

  socket.on("open", () => {
    console.log("Connected to IoT WebSocket");
  });

  socket.on("message", async (data) => {
  console.log("Raw IoT message:", data.toString()); // Always show what arrives
  try {
    const json = JSON.parse(data.toString());
    console.log("Received IoT JSON:", json);

    // Pass directly into the controller
    await vehicleController.updateCoordinatesLogic(io, json);

  } catch (err) {
    console.error("Failed to parse IoT message:", err);
  }
});

  socket.on("error", (err) => {
    console.error("WebSocket error:", err.message);
  });

  socket.on("close", () => {
    console.log("WebSocket closed. Reconnecting...");
    setTimeout(() => connectIoTData(io), 5000);
  });
}

module.exports = { connectIoTData };
