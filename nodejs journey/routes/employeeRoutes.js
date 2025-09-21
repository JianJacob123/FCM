const express = require('express');
const router = express.Router();
const EmployeeController = require('../controllers/employeeController');

// GET /api/employees - Get all employees with pagination and filtering
router.get('/', EmployeeController.getAllEmployees);

// GET /api/employees/position/:position - Get employees by position
router.get('/position/:position', EmployeeController.getEmployeesByPosition);

// GET /api/employees/:id - Get employee by ID
router.get('/:id', EmployeeController.getEmployeeById);

// POST /api/employees - Create new employee
router.post('/', EmployeeController.createEmployee);

// PUT /api/employees/:id - Update employee
router.put('/:id', EmployeeController.updateEmployee);

// PATCH /api/employees/:id/toggle-status - Toggle employee status
router.patch('/:id/toggle-status', EmployeeController.toggleEmployeeStatus);

// DELETE /api/employees/:id - Delete employee
router.delete('/:id', EmployeeController.deleteEmployee);

module.exports = router;
