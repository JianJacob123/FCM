const db = require('../config/db');

async function query(sql, params = []) {
  const res = await db.query(sql, params);
  return res.rows;
}

async function listByDate(date) {
  const sql = `
    SELECT id, schedule_date, time_start, vehicle_id, status, reason
    FROM schedules
    WHERE schedule_date = $1
    ORDER BY time_start NULLS LAST, id
  `;
  return await query(sql, [date]);
}

async function create(data) {
  // Some databases may not have an auto-increment default on id. Ensure an id is generated.
  const sql = `
    INSERT INTO schedules (id, schedule_date, time_start, vehicle_id, status, reason)
    VALUES ((SELECT COALESCE(MAX(id), 0) + 1 FROM schedules), $1, $2, $3, $4, $5)
    RETURNING id
  `;
  const rows = await query(sql, [
    data.schedule_date,
    data.time_start || null,
    data.vehicle_id || null,
    data.status,
    data.reason || null,
  ]);
  return rows[0];
}

async function update(id, data) {
  const fields = [];
  const params = [];
  let i = 1;
  for (const [k, v] of Object.entries(data)) {
    fields.push(`${k} = $${i++}`);
    params.push(v);
  }
  if (!fields.length) return;
  params.push(id);
  const sql = `UPDATE schedules SET ${fields.join(', ')} WHERE id = $${i}`;
  await query(sql, params);
}

async function remove(id) {
  await query('DELETE FROM schedules WHERE id = $1', [id]);
}

module.exports = { listByDate, create, update, remove };


