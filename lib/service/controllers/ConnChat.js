// controllers/ConnChat.js
const dbConnection = require('../config/database');
const path = require('path');
const fs = require('fs');

// Get all chats
exports.getAllChats = (req, res) => {
    const query = `
        SELECT c.id_chat, c.id_users, u.username, c.chat, c.date, c.for_users, c.images, c.voice_note
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
        SELECT c.id_chat, c.id_users, u.username, c.chat, c.date, c.for_users, c.images, c.voice_note
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
            // Convert images and voice notes to base64 if they exist
            const processedResults = results.map(result => {
                if (result.images && result.images !== 'NoImages') {
                    try {
                        const imagePath = path.join(__dirname, '..', '..', 'images', result.images);
                        const imageBuffer = fs.readFileSync(imagePath);
                        result.images = `data:image/jpeg;base64,${imageBuffer.toString('base64')}`;
                    } catch (error) {
                        console.error('Error reading image:', error);
                        result.images = null;
                    }
                }
                if (result.voice_note && result.voice_note !== 'NoVoice') {
                    try {
                        const voicePath = path.join(__dirname, '..', '..', 'voice', result.voice_note);
                        const voiceBuffer = fs.readFileSync(voicePath);
                        result.voice_note = `data:audio/mp3;base64,${voiceBuffer.toString('base64')}`;
                    } catch (error) {
                        console.error('Error reading voice note:', error);
                        result.voice_note = null;
                    }
                }
                return result;
            });

            res.status(200).json({
                message: 'Chats fetched successfully',
                data: processedResults
            });
        }
    });
};

// Create a new chat
exports.createChat = (req, res) => {
    const { id_users, chat, for_users } = req.body;
    let images = 'NoImages';
    let voice_note = 'NoVoice';

    // Handle voice note upload if present
    if (req.files && req.files.voice_note) {
        const voiceFile = req.files.voice_note;
        const allowedVoiceTypes = [
            'audio/mp3',
            'audio/mpeg',
            'audio/wav',
            'audio/ogg'
        ];

        if (!allowedVoiceTypes.includes(voiceFile.mimetype)) {
            return res.status(400).json({
                error: 'Invalid file type',
                message: 'Please upload a valid audio file'
            });
        }

        // Generate unique filename for voice note
        const timestamp = Date.now();
        const voiceExt = voiceFile.name.split('.').pop();
        const voiceFilename = `voice_${timestamp}.${voiceExt}`;

        // Set path to voice directory and create if it doesn't exist
        const voiceDir = path.join(__dirname, '..', '..', 'voice');
        if (!fs.existsSync(voiceDir)) {
            fs.mkdirSync(voiceDir, { recursive: true });
        }

        // Move voice file to voice directory
        try {
            voiceFile.mv(path.join(voiceDir, voiceFilename));
            voice_note = voiceFilename;
        } catch (err) {
            return res.status(500).json({
                error: 'Error handling voice file upload',
                details: err.message
            });
        }
    }

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
        const imagesDir = path.join(__dirname, '..', '..', 'images');
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
                const query = 'INSERT INTO chats (id_users, chat, date, for_users, images, voice_note) VALUES (?, ?, NOW(), ?, ?, ?)';
                dbConnection.query(query, [id_users, chat, for_users, images, voice_note], (err, result) => {
                    if (err) {
                        // If database insert fails, delete the uploaded files
                        fs.unlinkSync(path.join(imagesDir, filename));
                        if (voice_note !== 'NoVoice') {
                            fs.unlinkSync(path.join(voiceDir, voice_note));
                        }
                        res.status(500).json({ error: 'Error creating chat', details: err.message });
                    } else {
                        // Read the uploaded image and convert to base64
                        try {
                            const imageBuffer = fs.readFileSync(path.join(imagesDir, filename));
                            const base64Image = `data:${file.mimetype};base64,${imageBuffer.toString('base64')}`;
                            
                            let response = {
                                message: 'Chat created successfully',
                                id_chat: result.insertId,
                                images: base64Image
                            };

                            // Add voice note to response if exists
                            if (voice_note !== 'NoVoice') {
                                const voiceBuffer = fs.readFileSync(path.join(voiceDir, voice_note));
                                response.voice_note = `data:audio/mp3;base64,${voiceBuffer.toString('base64')}`;
                            }

                            res.status(201).json(response);
                        } catch (error) {
                            res.status(201).json({
                                message: 'Chat created successfully but error reading files',
                                id_chat: result.insertId
                            });
                        }
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
        // If no image, just insert the chat with voice note if present
        const query = 'INSERT INTO chats (id_users, chat, date, for_users, images, voice_note) VALUES (?, ?, NOW(), ?, ?, ?)';
        dbConnection.query(query, [id_users, chat, for_users, images, voice_note], (err, result) => {
            if (err) {
                if (voice_note !== 'NoVoice') {
                    fs.unlinkSync(path.join(voiceDir, voice_note));
                }
                res.status(500).json({ error: 'Error creating chat', details: err.message });
            } else {
                let response = {
                    message: 'Chat created successfully',
                    id_chat: result.insertId
                };

                // Add voice note to response if exists
                if (voice_note !== 'NoVoice') {
                    try {
                        const voiceBuffer = fs.readFileSync(path.join(voiceDir, voice_note));
                        response.voice_note = `data:audio/mp3;base64,${voiceBuffer.toString('base64')}`;
                    } catch (error) {
                        console.error('Error reading voice note:', error);
                    }
                }

                res.status(201).json(response);
            }
        });
    }
};

// Delete a chat
exports.deleteChat = (req, res) => {
    const id_chat = req.params.id_chat;
    
    // First get the image and voice note filenames if they exist
    const getFilesQuery = 'SELECT images, voice_note FROM chats WHERE id_chat = ?';
    dbConnection.query(getFilesQuery, [id_chat], (err, results) => {
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
                    const imagePath = path.join(__dirname, '..', '..', 'images', results[0].images);
                    if (fs.existsSync(imagePath)) {
                        fs.unlinkSync(imagePath);
                    }
                }
                // If chat had a voice note, delete it
                if (results[0] && results[0].voice_note !== 'NoVoice') {
                    const voicePath = path.join(__dirname, '..', '..', 'voice', results[0].voice_note);
                    if (fs.existsSync(voicePath)) {
                        fs.unlinkSync(voicePath);
                    }
                }
                res.status(200).json({
                    message: 'Chat deleted successfully'
                });
            }
        });
    });
};
