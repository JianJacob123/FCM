const db = require('../config/db');

class Employee {
  constructor(data) {
    this.id = data.id;
    this.full_name = data.full_name;
    this.position = data.position;
    this.active = data.active;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Get all employees with pagination and filtering
  static async getAll(page = 1, limit = 15, position = null, active = null) {
    try {
      let sql = `
        SELECT id, full_name, position, active, created_at, updated_at
        FROM employees
        WHERE 1=1
      `;
      const params = [];
      let paramCount = 0;

      if (position) {
        paramCount++;
        sql += ` AND position = $${paramCount}`;
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
        SELECT id, full_name, position, active, created_at, updated_at
        FROM employees
        WHERE id = $1
      `;
      const result = await db.query(sql, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      return new Employee(result.rows[0]);
    } catch (error) {
      console.error('Error fetching employee by ID:', error);
      throw error;
    }
  }

  // Create new employee
  static async create(data) {
    try {
      const sql = `
        INSERT INTO employees (full_name, position, active)
        VALUES ($1, $2, $3)
        RETURNING id, full_name, position, active, created_at, updated_at
      `;
      const result = await db.query(sql, [
        data.full_name,
        data.position,
        data.active !== undefined ? data.active : true
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
        fields.push(`position = $${paramCount}`);
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
        UPDATE employees 
        SET ${fields.join(', ')}
        WHERE id = $${paramCount}
        RETURNING id, full_name, position, active, created_at, updated_at
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
      const sql = 'DELETE FROM employees WHERE id = $1';
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
        SELECT id, full_name, position, active, created_at, updated_at
        FROM employees
        WHERE position = $1 AND active = true
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
      let sql = 'SELECT COUNT(*) as count FROM employees WHERE 1=1';
      const params = [];
      let paramCount = 0;

      if (position) {
        paramCount++;
        sql += ` AND position = $${paramCount}`;
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
}

module.exports = Employee;
