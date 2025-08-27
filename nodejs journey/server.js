// server
const express = require('express');
const { createServer } = require("http");
const { Server } = require("socket.io");
const app = express();
const cors = require('cors');
const httpServer = createServer(app);
const port = 8080;

//route imports
const vehicleRoutes = require('./routes/vehicleRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const tripRoutes = require('./routes/tripRoutes');
const userRoutes = require('./routes/userRoutes');
const favLocationRoutes = require('./routes/favLocationsRoutes');
const { startCronJobs } = require('./services/cronJobs');
const socketHandler = require("./sockets/socketHandler");
const vehicleSocketHandler = require("./sockets/vehicleHandler");

app.use(express.json());
app.use(cors());
app.use('/vehicles', vehicleRoutes);
app.use('/notifications', notificationRoutes)
app.use('/users', userRoutes);
app.use('/trips', tripRoutes);
app.use('/favLocations', favLocationRoutes);


const io = new Server(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

startCronJobs(io);

// --- Setup namespaces ---
const chatNamespace = io.of("/chat");
const vehicleNamespace = io.of("/vehicles");

// Attach handlers separately
socketHandler(chatNamespace);
vehicleSocketHandler(vehicleNamespace);


httpServer.listen(port, () => {
  console.log(`🚀 Server running on http://localhost:${port}`);
});

/*app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});*/