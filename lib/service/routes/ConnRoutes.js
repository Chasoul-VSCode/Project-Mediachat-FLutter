// routes/ConnRoutes.js
const express = require('express');
const router = express.Router();
const ConnController = require('../controllers/ConnController');

router.get('/conn', ConnController.connDB);

module.exports = router;
