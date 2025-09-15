const express = require('express');

const app = express();

const iotData = [
  {
    vehicle_id: 1,
    lat: 13.9538,
    lng: 121.1622,
    timestamp: "2025-08-11T14:30:00Z"
  },
  {
    vehicle_id: 2,
    lat: 14.6035,
    lng: 120.9876,
    timestamp: "2025-08-11T14:31:00Z"
  }
];

app.get('/iot-data', (req, res) => {
  res.json(iotData);
});

app.listen(4000, () => {
  console.log('IoT Server is running at http://localhost:4000');
});