const express = require('express');
const router = express.Router();

const ConnController = require('../Controllers/ConnController');

// Using GET method for endpoint '/conn'
router.get('/conn', ConnController.connDB);
router.get('/test', (req, res) => {
    res.send('Test route works!');
});

// Add a new route for error handling
router.get('/error', (req, res) => {
    throw new Error('This is a test error');
});

// Add error handling middleware
router.use((err, req, res, next) => {
    console.error('Error in RoutesDatabase:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
});

module.exports = router;
