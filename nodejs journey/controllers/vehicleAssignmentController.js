const VehicleAssignment = require('../models/vehicleAssignmentModel');

class VehicleAssignmentController {
  // Get all vehicle assignments
  static async getAllAssignments(req, res) {
    try {
      const assignments = await VehicleAssignment.getAll();
      res.json({
        success: true,
        data: assignments
      });
    } catch (error) {
      console.error('Error fetching vehicle assignments:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch vehicle assignments',
        error: error.message
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

      res.json({
        success: true,
        data: assignment
      });
    } catch (error) {
      console.error('Error fetching assignment:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch assignment',
        error: error.message
      });
    }
  }

  // Create new assignment
  static async createAssignment(req, res) {
    try {
      const { vehicle_id, driver_id, conductor_id } = req.body;

      // Validate required fields
      if (!vehicle_id) {
        return res.status(400).json({
          success: false,
          message: 'Vehicle ID is required'
        });
      }

      if (!driver_id && !conductor_id) {
        return res.status(400).json({
          success: false,
          message: 'At least one of Driver ID or Conductor ID is required'
        });
      }

      const assignment = await VehicleAssignment.create(vehicle_id, driver_id, conductor_id);

      res.status(201).json({
        success: true,
        message: 'Assignment created successfully',
        data: assignment
      });
    } catch (error) {
      console.error('Error creating assignment:', error);
      res.status(400).json({
        success: false,
        message: error.message || 'Failed to create assignment'
      });
    }
  }

  // Update assignment
  static async updateAssignment(req, res) {
    try {
      const { id } = req.params;
      const { vehicle_id, driver_id, conductor_id } = req.body;

      const assignment = await VehicleAssignment.update(id, vehicle_id, driver_id, conductor_id);

      res.json({
        success: true,
        message: 'Assignment updated successfully',
        data: assignment
      });
    } catch (error) {
      console.error('Error updating assignment:', error);
      res.status(400).json({
        success: false,
        message: error.message || 'Failed to update assignment'
      });
    }
  }

  // Delete assignment
  static async deleteAssignment(req, res) {
    try {
      const { id } = req.params;
      await VehicleAssignment.delete(id);

      res.json({
        success: true,
        message: 'Assignment deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting assignment:', error);
      res.status(400).json({
        success: false,
        message: error.message || 'Failed to delete assignment'
      });
    }
  }

  // Get available vehicles
  static async getAvailableVehicles(req, res) {
    try {
      const vehicles = await VehicleAssignment.getAvailableVehicles();
      res.json({
        success: true,
        data: vehicles
      });
    } catch (error) {
      console.error('Error fetching available vehicles:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch available vehicles',
        error: error.message
      });
    }
  }

  // Get available drivers
  static async getAvailableDrivers(req, res) {
    try {
      const drivers = await VehicleAssignment.getAvailableDrivers();
      res.json({
        success: true,
        data: drivers
      });
    } catch (error) {
      console.error('Error fetching available drivers:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch available drivers',
        error: error.message
      });
    }
  }

  // Get available conductors
  static async getAvailableConductors(req, res) {
    try {
      const conductors = await VehicleAssignment.getAvailableConductors();
      res.json({
        success: true,
        data: conductors
      });
    } catch (error) {
      console.error('Error fetching available conductors:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch available conductors',
        error: error.message
      });
    }
  }

  // Get all vehicles with assignment status
  static async getAllVehiclesWithStatus(req, res) {
    try {
      const vehicles = await VehicleAssignment.getAllVehiclesWithStatus();
      res.json({
        success: true,
        data: vehicles
      });
    } catch (error) {
      console.error('Error fetching vehicles with status:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch vehicles with status',
        error: error.message
      });
    }
  }
}

module.exports = VehicleAssignmentController;
