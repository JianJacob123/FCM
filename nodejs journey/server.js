
// server
const express = require('express');
const { createServer } = require("http");
const { Server } = require("socket.io");
const app = express();
const cors = require('cors');
const httpServer = createServer(app);
require('dotenv').config();

const PORT = process.env.PORT || 8080;

//route imports
const vehicleRoutes = require('./routes/vehicleRoutes');
const activityLogsRoute = require('./routes/activityLogsRoute');
const notificationRoutes = require('./routes/notificationRoutes');
const tripRoutes = require('./routes/tripRoutes');
const userRoutes = require('./routes/userRoutes');
const favLocationRoutes = require('./routes/favLocationsRoutes');
const getRoute = require('./routes/mapBoxRoute');
const passengerTripRoutes = require('./routes/passengerTripRoutes');
const scheduleRoutes = require('./routes/scheduleRoutes');
const tripMetricsRoutes = require('./routes/tripRoutes');
const employeeRoutes = require('./routes/employeeRoutes');
const vehicleAssignmentRoutes = require('./routes/vehicleAssignmentRoutes');
const { startCronJobs } = require('./services/cronJobs');
const socketHandler = require("./sockets/socketHandler");
const vehicleSocketHandler = require("./sockets/vehicleHandler");
const notificationHandler = require("./sockets/notificationHandler");

app.use(express.json());
app.use(cors());
app.use('/vehicles', vehicleRoutes);
app.use('/activityLogs', activityLogsRoute);
app.use('/notifications', notificationRoutes)
app.use('/users', userRoutes);
app.use('/trips', tripRoutes);
app.use('/favLocations', favLocationRoutes);
app.use('/route', getRoute);
app.use('/passengerTrips', passengerTripRoutes);
app.use(scheduleRoutes);
app.use(tripMetricsRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/vehicle-assignments', vehicleAssignmentRoutes);
app.use('/api/users', userRoutes);


const io = new Server(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

startCronJobs(io);

// --- Setup namespaces ---
const tripStatusNamespace = io.of("/tripstatus");
const vehicleNamespace = io.of("/vehicles");
const notificationNamespace = io.of("/notifications");

// Attach handlers separately
socketHandler(tripStatusNamespace);
vehicleSocketHandler(vehicleNamespace);
notificationHandler(notificationNamespace);

// IoT WebSocket connection
const { connectIoTData } = require("./services/coordinates");
connectIoTData(io);


httpServer.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

/*app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});*/