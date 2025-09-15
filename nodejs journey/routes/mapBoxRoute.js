const routeController = require('../controllers/routeController');
const router = require('express').Router();
const express = require('express');

router.post('/getRoute', routeController.getRoute);

module.exports = router;