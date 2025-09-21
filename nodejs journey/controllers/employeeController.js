const Employee = require('../models/employeeModel');

class EmployeeController {
  // Get all employees with pagination and filtering
  static async getAllEmployees(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 15;
      const position = req.query.position || null;
      const active = req.query.active !== undefined ? req.query.active === 'true' : null;

      const employees = await Employee.getAll(page, limit, position, active);
      const totalCount = await Employee.getCount(position, active);
      const totalPages = Math.ceil(totalCount / limit);

      res.json({
        success: true,
        data: employees,
        pagination: {
          currentPage: page,
          totalPages,
          totalCount,
          limit,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      });
    } catch (error) {
      console.error('Error in getAllEmployees:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch employees',
        error: error.message
      });
    }
  }

  // Get employee by ID
  static async getEmployeeById(req, res) {
    try {
      const { id } = req.params;
      const employee = await Employee.getById(id);

      if (!employee) {
        return res.status(404).json({
          success: false,
          message: 'Employee not found'
        });
      }

      res.json({
        success: true,
        data: employee
      });
    } catch (error) {
      console.error('Error in getEmployeeById:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch employee',
        error: error.message
      });
    }
  }

  // Create new employee
  static async createEmployee(req, res) {
    try {
      const { full_name, position, active } = req.body;

      // Validation
      if (!full_name || !position) {
        return res.status(400).json({
          success: false,
          message: 'Full name and position are required'
        });
      }

      const validPositions = ['Driver', 'Conductor', 'Admin', 'Manager'];
      if (!validPositions.includes(position)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid position. Must be one of: Driver, Conductor, Admin, Manager'
        });
      }

      const employee = await Employee.create({
        full_name: full_name.trim(),
        position,
        active: active !== undefined ? active : true
      });

      res.status(201).json({
        success: true,
        message: 'Employee created successfully',
        data: employee
      });
    } catch (error) {
      console.error('Error in createEmployee:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create employee',
        error: error.message
      });
    }
  }

  // Update employee
  static async updateEmployee(req, res) {
    try {
      const { id } = req.params;
      const { full_name, position, active } = req.body;

      // Check if employee exists
      const existingEmployee = await Employee.getById(id);
      if (!existingEmployee) {
        return res.status(404).json({
          success: false,
          message: 'Employee not found'
        });
      }

      // Validation
      if (position && !['Driver', 'Conductor', 'Admin', 'Manager'].includes(position)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid position. Must be one of: Driver, Conductor, Admin, Manager'
        });
      }

      const updateData = {};
      if (full_name !== undefined) updateData.full_name = full_name.trim();
      if (position !== undefined) updateData.position = position;
      if (active !== undefined) updateData.active = active;

      if (Object.keys(updateData).length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No valid fields to update'
        });
      }

      const employee = await Employee.update(id, updateData);

      res.json({
        success: true,
        message: 'Employee updated successfully',
        data: employee
      });
    } catch (error) {
      console.error('Error in updateEmployee:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update employee',
        error: error.message
      });
    }
  }

  // Delete employee
  static async deleteEmployee(req, res) {
    try {
      const { id } = req.params;

      // Check if employee exists
      const existingEmployee = await Employee.getById(id);
      if (!existingEmployee) {
        return res.status(404).json({
          success: false,
          message: 'Employee not found'
        });
      }

      const deleted = await Employee.delete(id);

      if (deleted) {
        res.json({
          success: true,
          message: 'Employee deleted successfully'
        });
      } else {
        res.status(500).json({
          success: false,
          message: 'Failed to delete employee'
        });
      }
    } catch (error) {
      console.error('Error in deleteEmployee:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to delete employee',
        error: error.message
      });
    }
  }

  // Get employees by position
  static async getEmployeesByPosition(req, res) {
    try {
      const { position } = req.params;
      
      if (!['Driver', 'Conductor', 'Admin', 'Manager'].includes(position)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid position. Must be one of: Driver, Conductor, Admin, Manager'
        });
      }

      const employees = await Employee.getByPosition(position);

      res.json({
        success: true,
        data: employees
      });
    } catch (error) {
      console.error('Error in getEmployeesByPosition:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch employees by position',
        error: error.message
      });
    }
  }

  // Toggle employee status (active/inactive)
  static async toggleEmployeeStatus(req, res) {
    try {
      const { id } = req.params;

      const existingEmployee = await Employee.getById(id);
      if (!existingEmployee) {
        return res.status(404).json({
          success: false,
          message: 'Employee not found'
        });
      }

      const employee = await Employee.update(id, {
        active: !existingEmployee.active
      });

      res.json({
        success: true,
        message: `Employee ${employee.active ? 'activated' : 'deactivated'} successfully`,
        data: employee
      });
    } catch (error) {
      console.error('Error in toggleEmployeeStatus:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to toggle employee status',
        error: error.message
      });
    }
  }
}

module.exports = EmployeeController;
