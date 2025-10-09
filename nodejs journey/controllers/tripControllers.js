const model = require('../models/tripModels');

const send = (res, status, body) => res.status(status).json(body);
const err = (res, status, message) => send(res, status, { success: false, message });

async function tripsPerUnit(req, res) {
  try {
    const { date } = req.query;
    const today = new Date();
    const d = date || today.toISOString().slice(0, 10);
    const rows = await model.countTripsPerVehicleForDate(d);
    return send(res, 200, { success: true, date: d, data: rows });
  } catch (e) {
    console.error('tripsPerUnit error', e);
    return err(res, 500, `Failed to compute trips per unit: ${e.message}`);
  }
}

module.exports = { tripsPerUnit };

async function fleetActivityByHour(req, res) {
  try {
    const { date } = req.query;
    const today = new Date();
    const d = date || today.toISOString().slice(0, 10);
    const rows = await model.countActiveVehiclesByHour(d);
    return send(res, 200, { success: true, date: d, data: rows });
  } catch (e) {
    console.error('fleetActivityByHour error', e);
    return err(res, 500, `Failed to compute fleet activity: ${e.message}`);
  }
}

module.exports.fleetActivityByHour = fleetActivityByHour;


