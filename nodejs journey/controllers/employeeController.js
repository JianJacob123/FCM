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

      // Allow any position value (including custom positions)
      // No validation needed for custom positions

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

      // Allow any position value (including custom positions)
      // No validation needed for custom positions

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
      
      // Allow any position value (including custom positions)
      // No validation needed for custom positions

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

  // Assign vehicle to employee
  static async assignVehicle(req, res) {
    try {
      const { id } = req.params;
      const { vehicle_id } = req.body;

      if (!vehicle_id) {
        return res.status(400).json({
          success: false,
          message: 'Vehicle ID is required'
        });
      }

      const employee = await Employee.getById(id);
      if (!employee) {
        return res.status(404).json({
          success: false,
          message: 'Employee not found'
        });
      }

      const assignmentId = await Employee.assignVehicle(id, vehicle_id);

      res.json({
        success: true,
        message: 'Vehicle assigned successfully',
        data: { assignment_id: assignmentId }
      });
    } catch (error) {
      console.error('Error in assignVehicle:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to assign vehicle',
        error: error.message
      });
    }
  }

  // Unassign vehicle from employee
  static async unassignVehicle(req, res) {
    try {
      const { id } = req.params;

      const employee = await Employee.getById(id);
      if (!employee) {
        return res.status(404).json({
          success: false,
          message: 'Employee not found'
        });
      }

      await Employee.unassignVehicle(id);

      res.json({
        success: true,
        message: 'Vehicle unassigned successfully'
      });
    } catch (error) {
      console.error('Error in unassignVehicle:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to unassign vehicle',
        error: error.message
      });
    }
  }

  // Get available vehicles
  static async getAvailableVehicles(req, res) {
    try {
      const vehicles = await Employee.getAvailableVehicles();

      res.json({
        success: true,
        data: vehicles
      });
    } catch (error) {
      console.error('Error in getAvailableVehicles:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch available vehicles',
        error: error.message
      });
    }
  }

  // Get all vehicles with assignment status
  static async getAllVehiclesWithStatus(req, res) {
    try {
      const vehicles = await Employee.getAllVehiclesWithStatus();

      res.json({
        success: true,
        data: vehicles
      });
    } catch (error) {
      console.error('Error in getAllVehiclesWithStatus:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch vehicles with status',
        error: error.message
      });
    }
  }
}

module.exports = EmployeeController;
