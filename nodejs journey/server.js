const express = require('express');
const app = express();
const vehicleRoutes = require('./routes/vehicleRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const tripRoutes = require('./routes/tripRoutes');
const { startCronJobs } = require('./services/cronJobs');
const port = 8080;

app.use(express.json());
app.use('/vehicles', vehicleRoutes);
app.use('/notifications', notificationRoutes)
app.use('/trips', tripRoutes);

startCronJobs();





app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});