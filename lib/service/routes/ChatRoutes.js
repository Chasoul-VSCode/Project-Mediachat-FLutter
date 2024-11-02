const express = require('express');
const router = express.Router();
const chatController = require('../controllers/ConnChat');

// Get all chats
router.get('/chats', chatController.getAllChats);

// Get chat by id
router.get('/chats/:id_users', chatController.getChatsByUserId);

// Create a new chat
router.post('/chats', chatController.createChat);

// Post images only 
router.post('/chats/images', chatController.postImages);

// Send voice note
router.post('/voice-note', chatController.sendVoiceNote);

// Delete a chat
router.delete('/chats/:id_chat', chatController.deleteChat);

// Get chat between two users
router.get('/chats/:id_users/:for_users', chatController.getChatsBetweenUsers);

module.exports = router;
