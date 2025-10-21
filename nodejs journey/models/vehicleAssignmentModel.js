const db = require('../config/db');

class VehicleAssignment {
  constructor(data) {
    this.assignment_id = data.assignment_id;
    this.vehicle_id = data.vehicle_id;
    this.plate_number = data.plate_number;
    this.driver_id = data.driver_id;
    this.conductor_id = data.conductor_id;
    this.assigned_at = data.assigned_at;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
    this.driver_name = data.driver_name;
    this.conductor_name = data.conductor_name;
  }

  // Get all vehicle assignments with driver and conductor details
  static async getAll() {
    try {
      const query = `
        SELECT 
          va.assignment_id,
          va.vehicle_id,
          v.plate_number,
          va.driver_id,
          va.conductor_id,
          va.assigned_at,
          va.created_at,
          va.updated_at,
          d.full_name as driver_name,
          c.full_name as conductor_name
        FROM vehicle_assignment va
        LEFT JOIN vehicles v ON va.vehicle_id = v.vehicle_id
        LEFT JOIN users d ON va.driver_id = d.user_id
        LEFT JOIN users c ON va.conductor_id = c.user_id
        ORDER BY va.assigned_at DESC
      `;
      const result = await db.query(query);
      return result.rows.map(row => new VehicleAssignment(row));
    } catch (error) {
      throw error;
    }
  }

  // Get assignment by ID
  static async getById(assignmentId) {
    try {
      const query = `
        SELECT 
          va.assignment_id,
          va.vehicle_id,
          va.driver_id,
          va.conductor_id,
          va.assigned_at,
          va.created_at,
          va.updated_at,
          d.full_name as driver_name,
          c.full_name as conductor_name
        FROM vehicle_assignment va
        LEFT JOIN users d ON va.driver_id = d.user_id
        LEFT JOIN users c ON va.conductor_id = c.user_id
        WHERE va.assignment_id = $1
      `;
      const result = await db.query(query, [assignmentId]);
      if (result.rows.length === 0) {
        return null;
      }
      return new VehicleAssignment(result.rows[0]);
    } catch (error) {
      throw error;
    }
  }

  // Create new assignment
  static async create(vehicleId, driverId, conductorId) {
    try {
      // Check if vehicle is already assigned
      const existingAssignment = await db.query(
        'SELECT assignment_id FROM vehicle_assignment WHERE vehicle_id = $1',
        [vehicleId]
      );

      if (existingAssignment.rows.length > 0) {
        throw new Error('Vehicle is already assigned');
      }

      // Check if driver is already assigned to another vehicle
      if (driverId) {
        const existingDriverAssignment = await db.query(
          'SELECT assignment_id FROM vehicle_assignment WHERE driver_id = $1',
          [driverId]
        );

        if (existingDriverAssignment.rows.length > 0) {
          throw new Error('Driver is already assigned to another vehicle');
        }
      }

      // Check if conductor is already assigned to another vehicle
      if (conductorId) {
        const existingConductorAssignment = await db.query(
          'SELECT assignment_id FROM vehicle_assignment WHERE conductor_id = $1',
          [conductorId]
        );

        if (existingConductorAssignment.rows.length > 0) {
          throw new Error('Conductor is already assigned to another vehicle');
        }
      }

      // Create the assignment
      // The table now requires a user_id column, so we need to provide it
      // Use driver_id as user_id if driver is provided, otherwise use conductor_id
      const userId = driverId || conductorId;
      if (!userId) {
        throw new Error('At least one user (driver or conductor) must be assigned');
      }
      
      const query = `
        INSERT INTO vehicle_assignment (vehicle_id, driver_id, conductor_id, user_id, assigned_at, created_at, updated_at)
        VALUES ($1, $2, $3, $4, NOW(), NOW(), NOW())
        RETURNING assignment_id, vehicle_id, driver_id, conductor_id, user_id, assigned_at, created_at, updated_at
      `;
      const result = await db.query(query, [vehicleId, driverId, conductorId, userId]);

      return new VehicleAssignment(result.rows[0]);
    } catch (error) {
      throw error;
    }
  }

  // Update assignment
  static async update(assignmentId, vehicleId, driverId, conductorId) {
    try {
      // Check if vehicle is already assigned to another assignment
      if (vehicleId) {
        const existingAssignment = await db.query(
          'SELECT assignment_id FROM vehicle_assignment WHERE vehicle_id = $1 AND assignment_id != $2',
          [vehicleId, assignmentId]
        );

        if (existingAssignment.rows.length > 0) {
          throw new Error('Vehicle is already assigned to another assignment');
        }
      }

      // Check if driver is already assigned to another vehicle
      if (driverId) {
        const existingDriverAssignment = await db.query(
          'SELECT assignment_id FROM vehicle_assignment WHERE driver_id = $1 AND assignment_id != $2',
          [driverId, assignmentId]
        );

        if (existingDriverAssignment.rows.length > 0) {
          throw new Error('Driver is already assigned to another vehicle');
        }
      }

      // Check if conductor is already assigned to another vehicle
      if (conductorId) {
        const existingConductorAssignment = await db.query(
          'SELECT assignment_id FROM vehicle_assignment WHERE conductor_id = $1 AND assignment_id != $2',
          [conductorId, assignmentId]
        );

        if (existingConductorAssignment.rows.length > 0) {
          throw new Error('Conductor is already assigned to another vehicle');
        }
      }

      // Build update query dynamically
      const updates = [];
      const values = [];
      let paramCount = 1;

      if (vehicleId !== undefined) {
        updates.push(`vehicle_id = $${paramCount}`);
        values.push(vehicleId);
        paramCount++;
      }

      if (driverId !== undefined) {
        updates.push(`driver_id = $${paramCount}`);
        values.push(driverId);
        paramCount++;
      }

      if (conductorId !== undefined) {
        updates.push(`conductor_id = $${paramCount}`);
        values.push(conductorId);
        paramCount++;
      }

      updates.push(`updated_at = NOW()`);
      values.push(assignmentId);

      const query = `
        UPDATE vehicle_assignment 
        SET ${updates.join(', ')}
        WHERE assignment_id = $${paramCount}
        RETURNING assignment_id, vehicle_id, driver_id, conductor_id, assigned_at, created_at, updated_at
      `;

      const result = await db.query(query, values);

      if (result.rows.length === 0) {
        throw new Error('Assignment not found');
      }

      return new VehicleAssignment(result.rows[0]);
    } catch (error) {
      throw error;
    }
  }

  // Delete assignment
  static async delete(assignmentId) {
    try {
      console.log('Model: Attempting to delete assignment with ID:', assignmentId);
      
      // Try to delete directly without checking existence first
      const query = 'DELETE FROM vehicle_assignment WHERE assignment_id = $1';
      const result = await db.query(query, [assignmentId]);
      
      console.log('Model: Delete query executed, affected rows:', result.rowCount);
      
      if (result.rowCount === 0) {
        throw new Error('Assignment not found or already deleted');
      }

      console.log('Model: Assignment deleted successfully');
      return true;
    } catch (error) {
      console.error('Model: Error in delete method:', error);
      console.error('Model: Error details:', {
        message: error.message,
        code: error.code,
        detail: error.detail,
        hint: error.hint
      });
      throw error;
    }
  }

  // Get available vehicles (not assigned)
  static async getAvailableVehicles() {
    try {
      const query = `
        SELECT v.vehicle_id, v.lat, v.lng, v.last_update
        FROM vehicles v
        WHERE v.vehicle_id NOT IN (
          SELECT DISTINCT vehicle_id 
          FROM vehicle_assignment 
          WHERE vehicle_id IS NOT NULL
        )
        ORDER BY v.vehicle_id
      `;
      const result = await db.query(query);
      return result.rows;
    } catch (error) {
      throw error;
    }
  }

  // Get available drivers
  static async getAvailableDrivers() {
    try {
      const query = `
        SELECT u.user_id, u.full_name, u.user_role, u.active
        FROM users u
        WHERE u.user_role = 'Driver'
        AND u.active = true
        AND u.user_id NOT IN (
          SELECT DISTINCT driver_id 
          FROM vehicle_assignment 
          WHERE driver_id IS NOT NULL
        )
        ORDER BY u.full_name
      `;
      const result = await db.query(query);
      return result.rows;
    } catch (error) {
      throw error;
    }
  }

  // Get available conductors
  static async getAvailableConductors() {
    try {
      const query = `
        SELECT u.user_id, u.full_name, u.user_role, u.active
        FROM users u
        WHERE u.user_role = 'Conductor'
        AND u.active = true
        AND u.user_id NOT IN (
          SELECT DISTINCT conductor_id 
          FROM vehicle_assignment 
          WHERE conductor_id IS NOT NULL
        )
        ORDER BY u.full_name
      `;
      const result = await db.query(query);
      return result.rows;
    } catch (error) {
      throw error;
    }
  }

  // Get all vehicles with assignment status
  static async getAllVehiclesWithStatus() {
    try {
      const query = `
        SELECT 
          v.vehicle_id,
          v.lat,
          v.lng,
          v.last_update,
          va.assignment_id,
          va.user_id,
          u.full_name as assigned_user_name,
          u.user_role as assigned_user_position
        FROM vehicles v
        LEFT JOIN vehicle_assignment va ON v.vehicle_id = va.vehicle_id
        LEFT JOIN users u ON va.user_id = u.user_id
        ORDER BY v.vehicle_id
      `;
      const result = await db.query(query);
      return result.rows;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = VehicleAssignment;
