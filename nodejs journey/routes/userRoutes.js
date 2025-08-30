const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.post('/login', userController.verifyLogin);
router.get('/getUserId', userController.getUserById);


module.exports = router;