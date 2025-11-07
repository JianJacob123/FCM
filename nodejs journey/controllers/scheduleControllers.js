const model = require('../models/scheduleModel');
const activityLogsModel = require('../models/activityLogsModel');
const { clearCache } = require('../middleware/cacheMiddleware');

const send = (res, status, body) => res.status(status).json(body);
const err = (res, status, message) => send(res, status, { success: false, message });

async function getByDate(req, res) {
  try {
    const { date } = req.query;
    if (!date) return err(res, 400, 'date is required (YYYY-MM-DD)');
    const data = await model.listByDate(date);
    return send(res, 200, { success: true, data });
  } catch (e) {
    console.error('getByDate error', e);
    return err(res, 500, 'Failed to fetch schedules');
  }
}

async function create(req, res) {
  try {
    const b = req.body || {};
    const required = ['schedule_date', 'status'];
    for (const k of required) if (!b[k]) return err(res, 400, `${k} is required`);
    
    // Validate vehicle_id if provided
    if (b.vehicle_id) {
      const vehicleModel = require('../models/vehicleModels');
      const vehicle = await vehicleModel.getVehicleById(b.vehicle_id);
      if (!vehicle) {
        return err(res, 400, `Vehicle with ID ${b.vehicle_id} does not exist`);
      }
    }
    
    const created = await model.create(b);
    await activityLogsModel.logActivity('create schedule', `Created schedule with ID ${created.id}`);
    // Clear cache for schedules endpoint
    clearCache('/api/schedules*');
    return send(res, 201, { success: true, id: created.id });
  } catch (e) {
    console.error('create schedule error', e);
    return err(res, 500, `Failed to create schedule: ${e.message}`);
  }
}

async function update(req, res) {
  try {
    const id = req.params.id;
    await model.update(id, req.body || {});
    await activityLogsModel.logActivity('Update Schedule', `Updated schedule with ID ${id}`);
    // Clear cache for schedules endpoint
    clearCache('/api/schedules*');
    return send(res, 200, { success: true });
  } catch (e) {
    console.error('update schedule error', e);
    return err(res, 500, 'Failed to update schedule');
  }
}

async function remove(req, res) {
  try {
    await model.remove(req.params.id);
    await activityLogsModel.logActivity('Delete Schedule', `Deleted schedule with ID ${req.params.id}`);
    // Clear cache for schedules endpoint
    clearCache('/api/schedules*');
    return send(res, 200, { success: true });
  } catch (e) {
    console.error('delete schedule error', e);
    return err(res, 500, 'Failed to delete schedule');
  }
}

module.exports = { getByDate, create, update, remove };


