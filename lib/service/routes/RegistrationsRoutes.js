// routes/RegistrationsRoutes.js
const express = require('express');
const router = express.Router();
const ConnRegistrations = require('../controllers/ConnRegistrations');

router.post('/registrations', ConnRegistrations.createRegistration);
router.get('/registrations', ConnRegistrations.getAllRegistrations);

module.exports = router;
