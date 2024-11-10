const express = require('express');
const router = express.Router();
const eventController = require('../controllers/ConnEvent');

// Get all events
router.get('/events', eventController.getAllEvents);
router.get('/events/users', eventController.getAllEventsWithUsers);

// Get single event by id
router.get('/events/:eventId', eventController.getEventById);

// Create new event
router.post('/events', eventController.createEvent);

module.exports = router;
