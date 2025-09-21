const express = require('express');
const router = express.Router();
const VehicleAssignmentController = require('../controllers/vehicleAssignmentController');

// Get all vehicle assignments
router.get('/', VehicleAssignmentController.getAllAssignments);

// Get assignment by ID
router.get('/:id', VehicleAssignmentController.getAssignmentById);

// Create new assignment
router.post('/', VehicleAssignmentController.createAssignment);

// Update assignment
router.put('/:id', VehicleAssignmentController.updateAssignment);

// Delete assignment
router.delete('/:id', VehicleAssignmentController.deleteAssignment);

// Get available vehicles (not assigned)
router.get('/vehicles/available', VehicleAssignmentController.getAvailableVehicles);

// Get available drivers
router.get('/drivers/available', VehicleAssignmentController.getAvailableDrivers);

// Get available conductors
router.get('/conductors/available', VehicleAssignmentController.getAvailableConductors);

// Get all vehicles with assignment status
router.get('/vehicles/status', VehicleAssignmentController.getAllVehiclesWithStatus);

module.exports = router;
