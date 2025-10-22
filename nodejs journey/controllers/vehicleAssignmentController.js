const VehicleAssignment = require('../models/vehicleAssignmentModel');
const activityLogsModel = require('../models/activityLogsModel');

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
      const { vehicle_id, driver_id, conductor_id, plate_number } = req.body;

      // Validate required fields
      if (!vehicle_id) {
        return res.status(400).json({
          success: false,
          message: 'Vehicle ID is required'
        });
      }

      if (!plate_number) {
        return res.status(400).json({
          success: false,
          message: 'Plate number is required'
        });
      }

      if (!driver_id && !conductor_id) {
        return res.status(400).json({
          success: false,
          message: 'At least one of Driver ID or Conductor ID is required'
        });
      }

      // Check if vehicle already exists
      const vehicleModel = require('../models/vehicleModels');
      const existingVehicle = await vehicleModel.getVehicleById(vehicle_id);
      
      let vehicle;
      if (!existingVehicle) {
        // Create new vehicle if it doesn't exist
        console.log(`Creating new vehicle with ID: ${vehicle_id} and plate: ${plate_number}`);
        vehicle = await vehicleModel.createVehicle(vehicle_id, plate_number);
      } else {
        // Use existing vehicle
        vehicle = existingVehicle;
        console.log(`Using existing vehicle with ID: ${vehicle_id}`);
      }

      // Create the assignment
      const assignment = await VehicleAssignment.create(vehicle_id, driver_id, conductor_id);

      res.status(201).json({
        success: true,
        message: 'Assignment created successfully',
        data: assignment
      });
      await activityLogsModel.logActivity('CREATE_ASSIGNMENT', `Created assignment for vehicle ${vehicle_id}`);
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
      const { vehicle_id, driver_id, conductor_id, plate_number } = req.body;

      // Validate required fields
      if (!vehicle_id) {
        return res.status(400).json({
          success: false,
          message: 'Vehicle ID is required'
        });
      }

      if (!plate_number) {
        return res.status(400).json({
          success: false,
          message: 'Plate number is required'
        });
      }

      // Get the current assignment to check if vehicle_id changed
      const currentAssignment = await VehicleAssignment.getById(id);
      if (!currentAssignment) {
        return res.status(404).json({
          success: false,
          message: 'Assignment not found'
        });
      }

      const oldVehicleId = currentAssignment.vehicle_id;
      const newVehicleId = vehicle_id;

      // If vehicle ID changed, we need to handle the vehicle update
      if (oldVehicleId !== newVehicleId) {
        console.log(`Vehicle ID changed from ${oldVehicleId} to ${newVehicleId}`);
        
        // Check if new vehicle exists
        const vehicleModel = require('../models/vehicleModels');
        const existingVehicle = await vehicleModel.getVehicleById(newVehicleId);
        
        if (!existingVehicle) {
          // Create new vehicle if it doesn't exist
          console.log(`Creating new vehicle with ID: ${newVehicleId} and plate: ${plate_number}`);
          await vehicleModel.createVehicle(newVehicleId, plate_number);
        } else {
          // Update existing vehicle's plate number
          console.log(`Updating existing vehicle ${newVehicleId} with new plate: ${plate_number}`);
          await vehicleModel.updateVehiclePlateNumber(newVehicleId, plate_number);
        }
      } else {
        // Same vehicle, just update plate number
        console.log(`Updating plate number for vehicle ${newVehicleId} to: ${plate_number}`);
        const vehicleModel = require('../models/vehicleModels');
        await vehicleModel.updateVehiclePlateNumber(newVehicleId, plate_number);
      }

      // Update the assignment
      const assignment = await VehicleAssignment.update(id, vehicle_id, driver_id, conductor_id);

      res.json({
        success: true,
        message: 'Assignment updated successfully',
        data: assignment
      });
      await activityLogsModel.logActivity('Update Vehicle Asssignment', `Assignment was updated for vehicle ${vehicle_id}`);
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
      console.log('=== DELETE ASSIGNMENT DEBUG ===');
      console.log('Raw ID from params:', id);
      console.log('ID type:', typeof id);
      
      // Validate ID
      if (!id) {
        console.log('ERROR: No ID provided');
        return res.status(400).json({
          success: false,
          message: 'Assignment ID is required'
        });
      }
      
      const assignmentId = parseInt(id);
      if (isNaN(assignmentId)) {
        console.log('ERROR: Invalid ID format:', id);
        return res.status(400).json({
          success: false,
          message: 'Invalid assignment ID format'
        });
      }
      
      console.log('Parsed assignment ID:', assignmentId);
      
      const result = await VehicleAssignment.delete(assignmentId);
      console.log('Delete result:', result);

      res.json({
        success: true,
        message: 'Assignment deleted successfully'
      });
      await activityLogsModel.logActivity('Vehicle Assignment Deleted', `Deleted assignment with ID ${assignmentId}`);
    } catch (error) {
      console.error('=== DELETE ERROR ===');
      console.error('Error type:', error.constructor.name);
      console.error('Error message:', error.message);
      console.error('Full error:', error);
      
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
