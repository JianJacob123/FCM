const express = require('express');
const router = express.Router();
const VehicleAssignmentController = require('../controllers/vehicleAssignmentController');

// GET /api/vehicle-assignments - Get all assignments with pagination
router.get('/', VehicleAssignmentController.getAllAssignments);

// GET /api/vehicle-assignments/vehicles/available - Get available vehicles for dropdown
router.get('/vehicles/available', VehicleAssignmentController.getAvailableVehicles);

// GET /api/vehicle-assignments/vehicles/all - Get all vehicles (including assigned ones)
router.get('/vehicles/all', VehicleAssignmentController.getAllVehicles);

// GET /api/vehicle-assignments/:id - Get assignment by ID
router.get('/:id', VehicleAssignmentController.getAssignmentById);

// POST /api/vehicle-assignments - Create new assignment
router.post('/', VehicleAssignmentController.createAssignment);

// PUT /api/vehicle-assignments/:id - Update assignment
router.put('/:id', VehicleAssignmentController.updateAssignment);

// DELETE /api/vehicle-assignments/:id - Delete assignment
router.delete('/:id', VehicleAssignmentController.deleteAssignment);

module.exports = router;
