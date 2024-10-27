const express = require('express');
const router = express.Router();
const chatController = require('../controllers/ConnChat');

// Get all chats
router.get('/chats', chatController.getAllChats);

// Get chat by id
router.get('/chats/:id_chat', chatController.getChatById);

// Create a new chat
router.post('/chats', chatController.createChat);

module.exports = router;
