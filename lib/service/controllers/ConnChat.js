// controllers/ConnChat.js
const dbConnection = require('../config/database');

// Get all chats
exports.getAllChats = (req, res) => {
    const query = `
        SELECT c.id_chat, c.id_users, u.username, c.chat, c.date, c.for_users 
        FROM chats c
        JOIN users u ON c.id_users = u.id_users
    `;
    dbConnection.query(query, (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching chats', details: err.message });
        } else {
            res.status(200).json({
                message: 'Chats fetched successfully',
                data: results
            });
        }
    });
};

// Get chat by id
exports.getChatsByUserId = (req, res) => {
    const id_users = req.params.id_users;
    const query = `
        SELECT c.id_chat, c.id_users, u.username, c.chat, c.date, c.for_users
        FROM chats c
        JOIN users u ON c.id_users = u.id_users
        WHERE c.id_users = ?
        ORDER BY c.date DESC
    `;
    dbConnection.query(query, [id_users], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching chats', details: err.message });
        } else if (results.length === 0) {
            res.status(404).json({ message: 'No chats found for this user' });
        } else {
            res.status(200).json({
                message: 'Chats fetched successfully',
                data: results
            });
        }
    });
};

// Create a new chat
exports.createChat = (req, res) => {
    const { id_users, chat, for_users } = req.body;
    const query = 'INSERT INTO chats (id_users, chat, date, for_users) VALUES (?, ?, NOW(), ?)';
    dbConnection.query(query, [id_users, chat, for_users], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error creating chat', details: err.message });
        } else {
            res.status(201).json({
                message: 'Chat created successfully',
                id_chat: result.insertId
            });
        }
    });
};

// Delete a chat
exports.deleteChat = (req, res) => {
    const id_chat = req.params.id_chat;
    const query = 'DELETE FROM chats WHERE id_chat = ?';
    dbConnection.query(query, [id_chat], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error deleting chat', details: err.message });
        } else if (result.affectedRows === 0) {
            res.status(404).json({ message: 'Chat not found' });
        } else {
            res.status(200).json({
                message: 'Chat deleted successfully'
            });
        }
    });
};
