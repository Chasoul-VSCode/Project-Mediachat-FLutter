// controllers/ConnChat.js
const dbConnection = require('../config/database');
const path = require('path');
const fs = require('fs');

// Get all chats
exports.getAllChats = (req, res) => {
    const query = `
        SELECT c.id_chat, c.id_users, u.username, c.chat, c.date, c.for_users, c.images
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
        SELECT c.id_chat, c.id_users, u.username, c.chat, c.date, c.for_users, c.images
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
    let images = 'NoImages';

    // Handle image upload if present
    if (req.files && req.files.images) {
        const file = req.files.images;
        const allowedTypes = [
            'image/jpeg', 
            'image/jpg', 
            'image/png', 
            'image/gif', 
            'image/bmp', 
            'image/webp', 
            'image/tiff',
            'image/svg+xml'
        ];

        if (!allowedTypes.includes(file.mimetype)) {
            return res.status(400).json({ 
                error: 'Invalid file type', 
                message: 'Please upload a valid image file' 
            });
        }

        // Generate unique filename
        const timestamp = Date.now();
        const ext = file.name.split('.').pop();
        const filename = `${timestamp}.${ext}`;

        // Set path to images directory and create if it doesn't exist
        const imagesDir = path.join(__dirname, '..', 'images');
        if (!fs.existsSync(imagesDir)) {
            fs.mkdirSync(imagesDir, { recursive: true });
        }
        
        // Move file to images directory
        try {
            file.mv(path.join(imagesDir, filename), (err) => {
                if (err) {
                    console.error('Error moving file:', err);
                    return res.status(500).json({ 
                        error: 'Error uploading image', 
                        details: err.message 
                    });
                }
                
                // Only proceed with database insert after successful file move
                images = filename;
                const query = 'INSERT INTO chats (id_users, chat, date, for_users, images) VALUES (?, ?, NOW(), ?, ?)';
                dbConnection.query(query, [id_users, chat, for_users, images], (err, result) => {
                    if (err) {
                        // If database insert fails, delete the uploaded file
                        fs.unlinkSync(path.join(imagesDir, filename));
                        res.status(500).json({ error: 'Error creating chat', details: err.message });
                    } else {
                        res.status(201).json({
                            message: 'Chat created successfully',
                            id_chat: result.insertId
                        });
                    }
                });
            });
        } catch (err) {
            return res.status(500).json({
                error: 'Error handling file upload',
                details: err.message
            });
        }
    } else {
        // If no image, just insert the chat
        const query = 'INSERT INTO chats (id_users, chat, date, for_users, images) VALUES (?, ?, NOW(), ?, ?)';
        dbConnection.query(query, [id_users, chat, for_users, images], (err, result) => {
            if (err) {
                res.status(500).json({ error: 'Error creating chat', details: err.message });
            } else {
                res.status(201).json({
                    message: 'Chat created successfully',
                    id_chat: result.insertId
                });
            }
        });
    }
};

// Delete a chat
exports.deleteChat = (req, res) => {
    const id_chat = req.params.id_chat;
    
    // First get the image filename if exists
    const getImageQuery = 'SELECT images FROM chats WHERE id_chat = ?';
    dbConnection.query(getImageQuery, [id_chat], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Error fetching chat details', details: err.message });
        }
        
        const query = 'DELETE FROM chats WHERE id_chat = ?';
        dbConnection.query(query, [id_chat], (err, result) => {
            if (err) {
                res.status(500).json({ error: 'Error deleting chat', details: err.message });
            } else if (result.affectedRows === 0) {
                res.status(404).json({ message: 'Chat not found' });
            } else {
                // If chat had an image, delete it
                if (results[0] && results[0].images !== 'NoImages') {
                    const imagePath = path.join(__dirname, '..', 'images', results[0].images);
                    if (fs.existsSync(imagePath)) {
                        fs.unlinkSync(imagePath);
                    }
                }
                res.status(200).json({
                    message: 'Chat deleted successfully'
                });
            }
        });
    });
};


