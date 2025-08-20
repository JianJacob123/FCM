const client = require('../config/db'); //db connection file

/*async function getIoTData() {
    const response = await axios.get('http://localhost:4000/iot-data');
    return response.data;
}*/

const getAllVehicles = async () => {
    try {
        const res = await client.query('SELECT * FROM vehicles');
        return res.rows;
    } catch (err) {
        console.error('Error fetching vehicles:', err);
        throw err;
    }
}

const getVehicleById = async (vehicleId) => {
    const sql = `SELECT * FROM vehicles WHERE vehicle_id = $1`;
    const res = await client.query(sql, [vehicleId]);
    return res.rows[0];
}


const updateVehicleCoordinates = async (vehicleId, latitude, longitude) => {
    const sql = `UPDATE vehicles SET lat = $1, lng = $2 WHERE vehicle_id = $3;`
    await client.query(sql, [latitude, longitude, vehicleId]);
}

const updateRouteId = async (vehicleId, routeId) => {
    const sql = `UPDATE vehicles SET route_id = $1 WHERE vehicle_id = $2;`;
    await client.query(sql, [routeId, vehicleId]);
}

module.exports = {
    getAllVehicles,
    getVehicleById,
    updateVehicleCoordinates,
    updateRouteId
};