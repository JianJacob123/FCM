const db = require('../config/db');

class VehicleAssignment {
  constructor(data) {
    this.assignment_id = data.assignment_id;
    this.vehicle_id = data.vehicle_id;
    this.driver = data.driver;
    this.conductor = data.conductor;
  }

  // Get all assignments with pagination
  static async getAll(page = 1, limit = 15) {
    try {
      const offset = (page - 1) * limit;
      
      // Get total count
      const countQuery = 'SELECT COUNT(*) as total FROM vehicle_users';
      const countResult = await db.query(countQuery);
      const total = parseInt(countResult.rows[0].total);
      
      // Get paginated results
      const query = `
        SELECT va.*, 
               CONCAT('FCM No. ', va.vehicle_id) as unit_number,
               CONCAT('ABC ', 1000 + va.vehicle_id) as plate_number
        FROM vehicle_users va
        ORDER BY va.assignment_id DESC
        LIMIT $1 OFFSET $2
      `;
      const rows = await db.query(query, [limit, offset]);
      
      return {
        assignments: rows.rows,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(total / limit),
          totalItems: total,
          itemsPerPage: limit
        }
      };
    } catch (error) {
      throw new Error(`Error fetching assignments: ${error.message}`);
    }
  }

  // Get assignment by ID
  static async getById(assignmentId) {
    try {
      const query = `
        SELECT va.*, 
               CONCAT('FCM No. ', va.vehicle_id) as unit_number,
               CONCAT('ABC ', 1000 + va.vehicle_id) as plate_number
        FROM vehicle_users va
        WHERE va.assignment_id = $1
      `;
      const rows = await db.query(query, [assignmentId]);
      
      if (rows.rows.length === 0) {
        return null;
      }
      
      return new VehicleAssignment(rows.rows[0]);
    } catch (error) {
      throw new Error(`Error fetching assignment: ${error.message}`);
    }
  }

  // Create new assignment
  static async create(assignmentData) {
    try {
      const { vehicle_id, driver, conductor } = assignmentData;
      
      // Check if vehicle already has an assignment
      const checkQuery = 'SELECT assignment_id FROM vehicle_users WHERE vehicle_id = $1';
      const existing = await db.query(checkQuery, [vehicle_id]);
      
      if (existing.rows.length > 0) {
        throw new Error('Vehicle already has an assignment');
      }
      
      const query = `
        INSERT INTO vehicle_users (vehicle_id, driver, conductor)
        VALUES ($1, $2, $3)
        RETURNING assignment_id
      `;
      const result = await db.query(query, [vehicle_id, driver, conductor]);
      
      return {
        assignment_id: result.rows[0].assignment_id,
        vehicle_id,
        driver,
        conductor
      };
    } catch (error) {
      throw new Error(`Error creating assignment: ${error.message}`);
    }
  }

  // Update assignment
  static async update(assignmentId, assignmentData) {
    try {
      const { vehicle_id, driver, conductor } = assignmentData;
      
      // Check if assignment exists
      const existing = await this.getById(assignmentId);
      if (!existing) {
        throw new Error('Assignment not found');
      }
      
      // Check if vehicle is already assigned to another assignment
      const checkQuery = 'SELECT assignment_id FROM vehicle_users WHERE vehicle_id = $1 AND assignment_id != $2';
      const conflict = await db.query(checkQuery, [vehicle_id, assignmentId]);
      
      if (conflict.rows.length > 0) {
        throw new Error('Vehicle already has another assignment');
      }
      
      const query = `
        UPDATE vehicle_users 
        SET vehicle_id = $1, driver = $2, conductor = $3
        WHERE assignment_id = $4
      `;
      await db.query(query, [vehicle_id, driver, conductor, assignmentId]);
      
      return await this.getById(assignmentId);
    } catch (error) {
      throw new Error(`Error updating assignment: ${error.message}`);
    }
  }

  // Delete assignment
  static async delete(assignmentId) {
    try {
      const query = 'DELETE FROM vehicle_users WHERE assignment_id = $1';
      const result = await db.query(query, [assignmentId]);
      
      if (result.rowCount === 0) {
        throw new Error('Assignment not found');
      }
      
      return { message: 'Assignment deleted successfully' };
    } catch (error) {
      throw new Error(`Error deleting assignment: ${error.message}`);
    }
  }

  // Get all vehicles for dropdown
  static async getAvailableVehicles() {
    try {
      const query = `
        SELECT v.vehicle_id, 
               CONCAT('FCM No. ', v.vehicle_id) as unit_number,
               CONCAT('ABC ', 1000 + v.vehicle_id) as plate_number
        FROM vehicles v
        LEFT JOIN vehicle_users va ON v.vehicle_id = va.vehicle_id
        WHERE va.vehicle_id IS NULL
        ORDER BY v.vehicle_id
      `;
      const rows = await db.query(query);
      return rows.rows;
    } catch (error) {
      throw new Error(`Error fetching available vehicles: ${error.message}`);
    }
  }

  // Get all vehicles (including assigned ones)
  static async getAllVehicles() {
    try {
      const query = `
        SELECT vehicle_id, 
               CONCAT('FCM No. ', vehicle_id) as unit_number,
               CONCAT('ABC ', 1000 + vehicle_id) as plate_number
        FROM vehicles
        ORDER BY vehicle_id
      `;
      const rows = await db.query(query);
      return rows.rows;
    } catch (error) {
      throw new Error(`Error fetching vehicles: ${error.message}`);
    }
  }
}

module.exports = VehicleAssignment;
