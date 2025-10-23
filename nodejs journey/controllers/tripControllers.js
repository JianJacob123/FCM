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

// Get all trips for admin dashboard
async function getAllTripsForAdmin(req, res) {
  try {
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;
    
    const trips = await model.getAllTrips(parseInt(limit), parseInt(offset));
    const totalCount = await model.getTotalTripsCount();
    
    return send(res, 200, { 
      success: true, 
      data: trips, 
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(totalCount),
        totalPages: Math.ceil(totalCount / limit)
      }
    });
  } catch (e) {
    console.error('getAllTripsForAdmin error', e);
    return err(res, 500, `Failed to fetch trips: ${e.message}`);
  }
}

module.exports.getAllTripsForAdmin = getAllTripsForAdmin;

// Get today's passenger count with time breakdown
async function getTodayPassengerCount(req, res) {
  try {
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const endOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
    
    const result = await model.getTodayPassengerCount(startOfDay, endOfDay);
    
    // Calculate percentages
    const total = result.total_passengers;
    const morningPct = total > 0 ? ((result.morning_passengers / total) * 100).toFixed(1) : 0;
    const middayPct = total > 0 ? ((result.midday_passengers / total) * 100).toFixed(1) : 0;
    const eveningPct = total > 0 ? ((result.evening_passengers / total) * 100).toFixed(1) : 0;
    
    return send(res, 200, { 
      success: true, 
      total_passengers: result.total_passengers,
      time_breakdown: {
        morning: {
          count: result.morning_passengers,
          percentage: parseFloat(morningPct)
        },
        midday: {
          count: result.midday_passengers,
          percentage: parseFloat(middayPct)
        },
        evening: {
          count: result.evening_passengers,
          percentage: parseFloat(eveningPct)
        }
      },
      date: today.toISOString().split('T')[0]
    });
  } catch (e) {
    console.error('getTodayPassengerCount error', e);
    return err(res, 500, `Failed to fetch today's passenger count: ${e.message}`);
  }
}

module.exports.getTodayPassengerCount = getTodayPassengerCount;


