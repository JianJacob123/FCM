const router = require('express').Router();
const ctrl = require('../controllers/scheduleControllers');

router.get('/api/schedules', ctrl.getByDate);
router.post('/api/schedules', ctrl.create);
router.put('/api/schedules/:id', ctrl.update);
router.delete('/api/schedules/:id', ctrl.remove);

module.exports = router;


