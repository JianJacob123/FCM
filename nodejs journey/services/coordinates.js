const client = require('../config/db'); //db connection file
const axios = require('axios');

async function getIoTData() {
    const response = await axios.get('http://localhost:4000/iot-data');
    return response.data;
}

module.exports = {
    getIoTData
}