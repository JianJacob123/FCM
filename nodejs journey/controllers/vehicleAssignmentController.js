const VehicleAssignment = require('../models/vehicleAssignmentModel');

class VehicleAssignmentController {
  // Get all assignments with pagination
  static async getAllAssignments(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 15;
      
      const result = await VehicleAssignment.getAll(page, limit);
      
      res.status(200).json({
        success: true,
        data: result.assignments,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('Error in getAllAssignments:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get assignment by ID
  static async getAssignmentById(req, res) {
    try {
      const { id } = req.params;
      const assignment = await VehicleAssignment.getById(id);
      
      if (!assignment) {
        return res.status(404).json({
          success: false,
          message: 'Assignment not found'
        });
      }
      
      res.status(200).json({
        success: true,
        data: assignment
      });
    } catch (error) {
      console.error('Error in getAssignmentById:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Create new assignment
  static async createAssignment(req, res) {
    try {
      const { vehicle_id, driver, conductor } = req.body;
      
      // Validation
      if (!vehicle_id || !driver || !conductor) {
        return res.status(400).json({
          success: false,
          message: 'Vehicle ID, driver name, and conductor name are required'
        });
      }
      
      if (driver.trim().length < 2) {
        return res.status(400).json({
          success: false,
          message: 'Driver name must be at least 2 characters long'
        });
      }
      
      if (conductor.trim().length < 2) {
        return res.status(400).json({
          success: false,
          message: 'Conductor name must be at least 2 characters long'
        });
      }
      
      const newAssignment = await VehicleAssignment.create({
        vehicle_id: parseInt(vehicle_id),
        driver: driver.trim(),
        conductor: conductor.trim()
      });
      
      res.status(201).json({
        success: true,
        message: 'Assignment created successfully',
        data: newAssignment
      });
    } catch (error) {
      console.error('Error in createAssignment:', error);
      
      if (error.message.includes('already has an assignment')) {
        return res.status(409).json({
          success: false,
          message: error.message
        });
      }
      
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update assignment
  static async updateAssignment(req, res) {
    try {
      const { id } = req.params;
      const { vehicle_id, driver, conductor } = req.body;
      
      // Validation
      if (!vehicle_id || !driver || !conductor) {
        return res.status(400).json({
          success: false,
          message: 'Vehicle ID, driver name, and conductor name are required'
        });
      }
      
      if (driver.trim().length < 2) {
        return res.status(400).json({
          success: false,
          message: 'Driver name must be at least 2 characters long'
        });
      }
      
      if (conductor.trim().length < 2) {
        return res.status(400).json({
          success: false,
          message: 'Conductor name must be at least 2 characters long'
        });
      }
      
      const updatedAssignment = await VehicleAssignment.update(id, {
        vehicle_id: parseInt(vehicle_id),
        driver: driver.trim(),
        conductor: conductor.trim()
      });
      
      res.status(200).json({
        success: true,
        message: 'Assignment updated successfully',
        data: updatedAssignment
      });
    } catch (error) {
      console.error('Error in updateAssignment:', error);
      
      if (error.message.includes('not found') || error.message.includes('already has another assignment')) {
        return res.status(400).json({
          success: false,
          message: error.message
        });
      }
      
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Delete assignment
  static async deleteAssignment(req, res) {
    try {
      const { id } = req.params;
      const result = await VehicleAssignment.delete(id);
      
      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      console.error('Error in deleteAssignment:', error);
      
      if (error.message.includes('not found')) {
        return res.status(404).json({
          success: false,
          message: error.message
        });
      }
      
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get available vehicles for dropdown
  static async getAvailableVehicles(req, res) {
    try {
      const vehicles = await VehicleAssignment.getAvailableVehicles();
      
      res.status(200).json({
        success: true,
        data: vehicles
      });
    } catch (error) {
      console.error('Error in getAvailableVehicles:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get all vehicles (including assigned ones)
  static async getAllVehicles(req, res) {
    try {
      const vehicles = await VehicleAssignment.getAllVehicles();
      
      res.status(200).json({
        success: true,
        data: vehicles
      });
    } catch (error) {
      console.error('Error in getAllVehicles:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = VehicleAssignmentController;
