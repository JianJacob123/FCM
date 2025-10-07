const routeController = require('../controllers/routeController');
const router = require('express').Router();

router.post('/getRoute', routeController.getRoute);

module.exports = router;