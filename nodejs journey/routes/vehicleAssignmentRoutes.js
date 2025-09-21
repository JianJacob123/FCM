const express = require('express');
const router = express.Router();
const VehicleAssignmentController = require('../controllers/vehicleAssignmentController');

// Vehicle assignment routes
router.get('/', VehicleAssignmentController.getAllAssignments);
router.get('/:id', VehicleAssignmentController.getAssignmentById);
router.post('/', VehicleAssignmentController.createAssignment);
router.put('/:id', VehicleAssignmentController.updateAssignment);
router.delete('/:id', VehicleAssignmentController.deleteAssignment);

// Get available vehicles for assignment
router.get('/vehicles/available', VehicleAssignmentController.getAvailableVehicles);

// Get all vehicles (for lookups)
router.get('/vehicles/all', VehicleAssignmentController.getAllVehicles);

module.exports = router;
