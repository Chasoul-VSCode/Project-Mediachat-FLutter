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
        ORDER BY c.date DESC
    `;
    dbConnection.query(query, (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching chats', details: err.message });
        } else {
            // Convert images and voice notes to base64 if they exist
            const processedResults = results.map(result => {
                if (result.images && result.images !== 'NoImages') {
                    try {
                        const imagePath = path.join(__dirname, '..', '..', 'images_chat', result.images);
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
                        const imagePath = path.join(__dirname, '..', '..', 'images_chat', result.images);
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

// Get chats between two users
exports.getChatsBetweenUsers = (req, res) => {
    const { id_users, for_users } = req.params;
    const query = `
        SELECT c.id_chat, c.id_users, u.username, c.chat, c.date, c.for_users, c.images, c.voice_note
        FROM chats c
        JOIN users u ON c.id_users = u.id_users
        WHERE (c.id_users = ? AND c.for_users = ?) OR (c.id_users = ? AND c.for_users = ?)
        ORDER BY c.date DESC
    `;
    dbConnection.query(query, [id_users, for_users, for_users, id_users], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching chats', details: err.message });
        } else {
            // Convert images and voice notes to base64 if they exist
            const processedResults = results.map(result => {
                if (result.images && result.images !== 'NoImages') {
                    try {
                        const imagePath = path.join(__dirname, '..', '..', 'images_chat', result.images);
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
    // Validate required fields
    if (!req.body.id_users || !req.body.for_users) {
        return res.status(400).json({
            error: 'Missing required fields',
            details: 'id_users and for_users are required'
        });
    }

    const { id_users, chat = 'NoChat', for_users } = req.body;
    let images = 'NoImages';
    let voice_note = 'NoVoice';
    let imagesDir, voiceDir;

    // Process base64 image if present
    if (req.body.images) {
        const base64Data = req.body.images.replace(/^data:image\/\w+;base64,/, '');
        const imageBuffer = Buffer.from(base64Data, 'base64');
        
        // Generate unique filename
        const timestamp = Date.now();
        const filename = `${timestamp}-chat.jpg`;
        
        // Set path to images_chat directory and create if it doesn't exist
        imagesDir = path.join(__dirname, '..', '..', 'images_chat');
        if (!fs.existsSync(imagesDir)) {
            fs.mkdirSync(imagesDir, { recursive: true });
        }

        // Save the image
        try {
            fs.writeFileSync(path.join(imagesDir, filename), imageBuffer);
            images = filename;
        } catch (err) {
            return res.status(500).json({
                error: 'Error saving image',
                details: err.message
            });
        }
    }

    // Process base64 voice note if present 
    if (req.body.voice_note) {
        const base64Voice = req.body.voice_note.replace(/^data:audio\/\w+;base64,/, '');
        const voiceBuffer = Buffer.from(base64Voice, 'base64');

        // Generate unique filename
        const timestamp = Date.now();
        const voiceFilename = `${timestamp}-voice.mp3`;

        // Set path to voice directory and create if it doesn't exist
        voiceDir = path.join(__dirname, '..', '..', 'voice');
        if (!fs.existsSync(voiceDir)) {
            fs.mkdirSync(voiceDir, { recursive: true });
        }

        // Save the voice note
        try {
            fs.writeFileSync(path.join(voiceDir, voiceFilename), voiceBuffer);
            voice_note = voiceFilename;
        } catch (err) {
            // If voice note save fails and image was saved, delete the image
            if (images !== 'NoImages') {
                fs.unlinkSync(path.join(imagesDir, images));
            }
            return res.status(500).json({
                error: 'Error saving voice note',
                details: err.message
            });
        }
    }

    // Insert chat into database
    const query = 'INSERT INTO chats (id_users, chat, date, for_users, images, voice_note) VALUES (?, ?, NOW(), ?, ?, ?)';
    dbConnection.query(query, [id_users, chat, for_users, images, voice_note], (err, result) => {
        if (err) {
            // If database insert fails, delete any uploaded files
            if (images !== 'NoImages') {
                fs.unlinkSync(path.join(imagesDir, images));
            }
            if (voice_note !== 'NoVoice') {
                fs.unlinkSync(path.join(voiceDir, voice_note));
            }
            return res.status(500).json({ 
                error: 'Error creating chat', 
                details: err.message 
            });
        }

        // Prepare response
        let response = {
            message: 'Chat created successfully',
            id_chat: result.insertId
        };

        // Add image to response if exists
        if (images !== 'NoImages') {
            try {
                const imageBuffer = fs.readFileSync(path.join(imagesDir, images));
                response.images = `data:image/jpeg;base64,${imageBuffer.toString('base64')}`;
            } catch (error) {
                console.error('Error reading saved image:', error);
            }
        }

        // Add voice note to response if exists
        if (voice_note !== 'NoVoice') {
            try {
                const voiceBuffer = fs.readFileSync(path.join(voiceDir, voice_note));
                response.voice_note = `data:audio/mp3;base64,${voiceBuffer.toString('base64')}`;
            } catch (error) {
                console.error('Error reading saved voice note:', error);
            }
        }

        res.status(201).json(response);
    });
};

// Post images only
exports.postImages = (req, res) => {
    const { id_users, for_users} = req.body;
    
    // Validate required fields
    if (!id_users || !for_users) {
        return res.status(400).json({ 
            error: 'Missing required fields',
            details: 'id_users and for_users are required'
        });
    }

    // Check if image exists in request files
    if (!req.files || !req.files.images) {
        return res.status(400).json({ error: 'No image data provided' });
    }

    const imageFile = req.files.images;
    const imagesDir = path.join(__dirname, '..', '..', 'images_chat');

    // Create directory if it doesn't exist
    if (!fs.existsSync(imagesDir)) {
        fs.mkdirSync(imagesDir, { recursive: true });
    }

    // Get file extension from original filename
    const fileExt = path.extname(imageFile.name).toLowerCase();
    
    // List of allowed image extensions
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    
    // Validate file extension
    if (!allowedExtensions.includes(fileExt)) {
        return res.status(400).json({
            error: 'Invalid file type',
            details: 'Only image files (jpg, jpeg, png, gif, webp, bmp) are allowed'
        });
    }

    // Generate unique filename with original extension
    const timestamp = Date.now();
    const images = `${timestamp}-chat${fileExt}`;

    // Save image file
    try {
        imageFile.mv(path.join(imagesDir, images));
    } catch (err) {
        return res.status(500).json({
            error: 'Error saving image file',
            details: err.message
        });
    }

    // Insert into database with empty chat and voice_note
    const query = 'INSERT INTO chats (id_users, chat, date, for_users, images, voice_note) VALUES (?, ?, NOW(), ?, ?, ?)';
    dbConnection.query(query, [id_users, 'Sent an image', for_users, images, 'NoVoice'], (err, result) => {
        if (err) {
            // Delete uploaded file if database insert fails
            fs.unlinkSync(path.join(imagesDir, images));
            return res.status(500).json({
                error: 'Error creating chat',
                details: err.message
            });
        }

        // Prepare response
        let response = {
            message: 'Image uploaded successfully',
            id_chat: result.insertId
        };

        // Add image to response
        try {
            const imageBuffer = fs.readFileSync(path.join(imagesDir, images));
            const mimeType = {
                '.jpg': 'image/jpeg',
                '.jpeg': 'image/jpeg', 
                '.png': 'image/png',
                '.gif': 'image/gif',
                '.webp': 'image/webp',
                '.bmp': 'image/bmp'
            }[fileExt];
            response.images = `data:${mimeType};base64,${imageBuffer.toString('base64')}`;
        } catch (error) {
            console.error('Error reading saved image:', error);
        }

        res.status(201).json(response);
    });
};

// Send voice note
exports.sendVoiceNote = (req, res) => {
    const { id_users, for_users } = req.body;
    const voiceFile = req.files?.voice_note;

    if (!voiceFile) {
        return res.status(400).json({
            error: 'No voice note file uploaded'
        });
    }

    // Create voice directory if it doesn't exist
    const voiceDir = path.join(__dirname, '..', '..', 'voice');
    if (!fs.existsSync(voiceDir)) {
        fs.mkdirSync(voiceDir, { recursive: true });
    }

    // Generate unique filename
    const timestamp = Date.now();
    const fileExt = path.extname(voiceFile.name);
    const voiceFileName = `${timestamp}-voice${fileExt}`;

    // Save voice file
    try {
        voiceFile.mv(path.join(voiceDir, voiceFileName));
    } catch (err) {
        return res.status(500).json({
            error: 'Error saving voice note file',
            details: err.message
        });
    }

    // Insert into database with NoImages for images field and empty chat
    const query = 'INSERT INTO chats (id_users, chat, date, for_users, images, voice_note) VALUES (?, ?, NOW(), ?, ?, ?)';
    dbConnection.query(query, [id_users, 'Tidak ada', for_users, 'NoImages', voiceFileName], (err, result) => {
        if (err) {
            // Delete uploaded file if database insert fails
            fs.unlinkSync(path.join(voiceDir, voiceFileName));
            return res.status(500).json({
                error: 'Error creating chat',
                details: err.message
            });
        }

        // Prepare response
        let response = {
            message: 'Voice note uploaded successfully',
            id_chat: result.insertId
        };

        // Add voice note to response
        try {
            const voiceBuffer = fs.readFileSync(path.join(voiceDir, voiceFileName));
            response.voice_note = `data:audio/mp3;base64,${voiceBuffer.toString('base64')}`;
        } catch (error) {
            console.error('Error reading saved voice note:', error);
        }

        res.status(201).json(response);
    });
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
        
        if (results.length === 0) {
            return res.status(404).json({ message: 'Chat not found' });
        }

        const query = 'DELETE FROM chats WHERE id_chat = ?';
        dbConnection.query(query, [id_chat], (err, result) => {
            if (err) {
                return res.status(500).json({ error: 'Error deleting chat', details: err.message });
            }

            // If chat had an image, delete it
            if (results[0].images !== 'NoImages') {
                const imagePath = path.join(__dirname, '..', '..', 'images_chat', results[0].images);
                if (fs.existsSync(imagePath)) {
                    try {
                        fs.unlinkSync(imagePath);
                    } catch (error) {
                        console.error('Error deleting image file:', error);
                    }
                }
            }

            // If chat had a voice note, delete it
            if (results[0].voice_note !== 'NoVoice') {
                const voicePath = path.join(__dirname, '..', '..', 'voice', results[0].voice_note);
                if (fs.existsSync(voicePath)) {
                    try {
                        fs.unlinkSync(voicePath);
                    } catch (error) {
                        console.error('Error deleting voice note file:', error);
                    }
                }
            }

            res.status(200).json({
                message: 'Chat deleted successfully'
            });
        });
    });
};
