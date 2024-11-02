const express = require('express');
const router = express.Router();
const communityController = require('../controllers/ConnCommunity');

// Get all communities
router.get('/communities', communityController.getAllCommunities);

// Get communities by user ID
router.get('/communities/:id_users', communityController.getCommunitiesByUserId);

// Create new community
router.post('/communities', communityController.createCommunity);

module.exports = router;
