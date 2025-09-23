const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Auth
router.post('/login', userController.verifyLogin);
router.get('/getUserId', userController.getUserById);

// Account management
router.get('/', userController.listUsers);
router.get('/:id', userController.getUserById);
router.post('/', userController.createUser);
router.put('/:id', userController.updateUser);
router.delete('/:id', userController.deleteUser);
router.post('/:id/reveal-password', userController.revealPassword);


module.exports = router;