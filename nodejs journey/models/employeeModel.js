const db = require('../config/db');

class Employee {
  constructor(data) {
    this.id = data.user_id
    this.full_name = data.full_name;
    this.position = data.user_role;
    this.active = data.active;
    this.current_vehicle_assignment_id = data.current_vehicle_assignment_id;
    //this.vehicle_info = data.vehicle_info || null;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Get all employees with pagination and filtering
  static async getAll(page = 1, limit = 15, position = null, active = null) {
    try {
      let sql = `
        SELECT 
          u.user_id, 
          u.full_name, 
          u.user_role, 
          u.active, 
          u.current_vehicle_assignment_id,
          va.vehicle_id,
          v.lat,
          v.lng,
          v.last_update as vehicle_last_update,
          u.created_at, 
          u.updated_at
        FROM users u
        LEFT JOIN vehicle_assignment va ON u.current_vehicle_assignment_id = va.assignment_id
        LEFT JOIN vehicles v ON va.vehicle_id = v.vehicle_id
        WHERE 1=1 AND u.user_role != 'admin'
      `;
      const params = [];
      let paramCount = 0;

      if (position) {
        paramCount++;
        sql += ` AND user_role = $${paramCount}`;
        params.push(position);
      }

      if (active !== null) {
        paramCount++;
        sql += ` AND active = $${paramCount}`;
        params.push(active);
      }

      sql += ` ORDER BY full_name ASC`;

      // Add pagination
      const offset = (page - 1) * limit;
      paramCount++;
      sql += ` LIMIT $${paramCount}`;
      params.push(limit);
      
      paramCount++;
      sql += ` OFFSET $${paramCount}`;
      params.push(offset);

      const result = await db.query(sql, params);
      return result.rows.map(row => new Employee(row));
    } catch (error) {
      console.error('Error fetching employees:', error);
      throw error;
    }
  }

  // Get employee by ID
  static async getById(id) {
    try {
      const sql = `
        SELECT 
          u.user_id, 
          u.full_name, 
          u.user_role, 
          u.active, 
          u.current_vehicle_assignment_id,
          va.vehicle_id,
          v.lat,
          v.lng,
          v.last_update as vehicle_last_update,
          u.created_at, 
          u.updated_at
        FROM users u
        LEFT JOIN vehicle_assignment va ON u.current_vehicle_assignment_id = va.assignment_id
        LEFT JOIN vehicles v ON va.vehicle_id = v.vehicle_id
        WHERE u.user_id = $1
      `;
      const result = await db.query(sql, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      const employee = new Employee(result.rows[0]);
      // Add vehicle info if available
      if (result.rows[0].vehicle_id) {
        employee.vehicle_info = {
          vehicle_id: result.rows[0].vehicle_id,
          lat: result.rows[0].lat,
          lng: result.rows[0].lng,
          last_update: result.rows[0].vehicle_last_update
        };
      }
      return employee;
    } catch (error) {
      console.error('Error fetching employee by ID:', error);
      throw error;
    }
  }

  // Create new employee
  static async create(data) {
    try {
      const sql = `
        INSERT INTO users (full_name, user_role, active, username, user_pass)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING user_id, full_name, user_role, active, created_at, updated_at
      `;
      const result = await db.query(sql, [
        data.full_name,
        data.position,
        data.active !== undefined ? data.active : true,
        data.username || data.full_name.toLowerCase().replace(/\s+/g, '_'),
        data.password || 'default_password'
      ]);
      
      return new Employee(result.rows[0]);
    } catch (error) {
      console.error('Error creating employee:', error);
      throw error;
    }
  }

  // Update employee
  static async update(id, data) {
    try {
      const fields = [];
      const params = [];
      let paramCount = 0;

      if (data.full_name !== undefined) {
        paramCount++;
        fields.push(`full_name = $${paramCount}`);
        params.push(data.full_name);
      }

      if (data.position !== undefined) {
        paramCount++;
        fields.push(`user_role = $${paramCount}`);
        params.push(data.position);
      }

      if (data.active !== undefined) {
        paramCount++;
        fields.push(`active = $${paramCount}`);
        params.push(data.active);
      }

      if (fields.length === 0) {
        throw new Error('No fields to update');
      }

      paramCount++;
      fields.push(`updated_at = CURRENT_TIMESTAMP`);
      params.push(id);

      const sql = `
        UPDATE users 
        SET ${fields.join(', ')}
        WHERE user_id = $${paramCount}
        RETURNING user_id, full_name, user_role, active, created_at, updated_at
      `;

      const result = await db.query(sql, params);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      return new Employee(result.rows[0]);
    } catch (error) {
      console.error('Error updating employee:', error);
      throw error;
    }
  }

  // Delete employee
  static async delete(id) {
    try {
      const sql = 'DELETE FROM users WHERE user_id = $1';
      const result = await db.query(sql, [id]);
      return result.rowCount > 0;
    } catch (error) {
      console.error('Error deleting employee:', error);
      throw error;
    }
  }

  // Get employees by position
  static async getByPosition(position) {
    try {
      const sql = `
        SELECT user_id, full_name, user_role, active, created_at, updated_at
        FROM users
        WHERE user_role = $1 AND active = true
        ORDER BY full_name ASC
      `;
      const result = await db.query(sql, [position]);
      return result.rows.map(row => new Employee(row));
    } catch (error) {
      console.error('Error fetching employees by position:', error);
      throw error;
    }
  }

  // Get total count for pagination
  static async getCount(position = null, active = null) {
    try {
      let sql = 'SELECT COUNT(*) as count FROM users WHERE 1=1';
      const params = [];
      let paramCount = 0;

      if (position) {
        paramCount++;
        sql += ` AND user_role = $${paramCount}`;
        params.push(position);
      }

      if (active !== null) {
        paramCount++;
        sql += ` AND active = $${paramCount}`;
        params.push(active);
      }

      const result = await db.query(sql, params);
      return parseInt(result.rows[0].count);
    } catch (error) {
      console.error('Error getting employee count:', error);
      throw error;
    }
  }

  // Assign vehicle to employee
  static async assignVehicle(userId, vehicleId) {
    try {
      // First, unassign any existing vehicle
      await this.unassignVehicle(userId);
      
      // Create new vehicle assignment
      const assignmentSql = `
        INSERT INTO vehicle_assignment (vehicle_id, user_id, assigned_at)
        VALUES ($1, $2, NOW())
        RETURNING assignment_id
      `;
      const assignmentResult = await db.query(assignmentSql, [vehicleId, userId]);
      const assignmentId = assignmentResult.rows[0].assignment_id;
      
      // Update user's current vehicle assignment
      const updateSql = `
        UPDATE users 
        SET current_vehicle_assignment_id = $1, updated_at = NOW()
        WHERE user_id = $2
      `;
      await db.query(updateSql, [assignmentId, userId]);
      
      return assignmentId;
    } catch (error) {
      console.error('Error assigning vehicle:', error);
      throw error;
    }
  }

  // Unassign vehicle from employee
  static async unassignVehicle(userId) {
    try {
      // Get current assignment
      const getAssignmentSql = `
        SELECT current_vehicle_assignment_id FROM users WHERE user_id = $1
      `;
      const result = await db.query(getAssignmentSql, [userId]);
      
      if (result.rows.length > 0 && result.rows[0].current_vehicle_assignment_id) {
        const assignmentId = result.rows[0].current_vehicle_assignment_id;
        
        // Update user to remove assignment
        const updateSql = `
          UPDATE users 
          SET current_vehicle_assignment_id = NULL, updated_at = NOW()
          WHERE user_id = $1
        `;
        await db.query(updateSql, [userId]);
        
        // Delete the assignment record
        const deleteSql = `DELETE FROM vehicle_assignment WHERE assignment_id = $1`;
        await db.query(deleteSql, [assignmentId]);
      }
      
      return true;
    } catch (error) {
      console.error('Error unassigning vehicle:', error);
      throw error;
    }
  }

  // Get available vehicles (not currently assigned)
  static async getAvailableVehicles() {
    try {
      const sql = `
        SELECT v.vehicle_id, v.lat, v.lng, v.last_update
        FROM vehicles v
        LEFT JOIN vehicle_assignment va ON v.vehicle_id = va.vehicle_id
        WHERE va.vehicle_id IS NULL
        ORDER BY v.vehicle_id
      `;
      const result = await db.query(sql);
      return result.rows;
    } catch (error) {
      console.error('Error getting available vehicles:', error);
      throw error;
    }
  }

  // Get all vehicles with assignment status
  static async getAllVehiclesWithStatus() {
    try {
      const sql = `
        SELECT 
          v.vehicle_id, 
          v.lat, 
          v.lng, 
          v.last_update,
          va.assignment_id,
          va.user_id,
          u.full_name as assigned_to
        FROM vehicles v
        LEFT JOIN vehicle_assignment va ON v.vehicle_id = va.vehicle_id
        LEFT JOIN users u ON va.user_id = u.user_id
        ORDER BY v.vehicle_id
      `;
      const result = await db.query(sql);
      return result.rows;
    } catch (error) {
      console.error('Error getting vehicles with status:', error);
      throw error;
    }
  }
}

module.exports = Employee;
