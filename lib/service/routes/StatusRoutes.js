const express = require('express');
const router = express.Router();
const statusController = require('../controllers/ConnStatus');

// Get all statuses
router.get('/status', statusController.getAllStatus);

// Post new status
router.post('/status', statusController.postStatus);

module.exports = router;
