const dbConnection = require('../config/database');
const path = require('path');
const fs = require('fs');

// Get all statuses
exports.getAllStatus = (req, res) => {
    const query = `
        SELECT s.id_status, s.id_users, s.caption, s.date, s.images_status,
               u.username, u.images_profile
        FROM status s
        JOIN users u ON s.id_users = u.id_users
        ORDER BY s.date DESC`;

    dbConnection.query(query, (err, results) => {
        if (err) {
            console.error('Error fetching statuses:', err);
            res.status(500).json({ error: 'Error fetching statuses' });
            return;
        }

        // Convert images to base64 if they exist
        results.forEach(status => {
            if (status.images_status && status.images_status !== 'NoImages') {
                try {
                    const imagePath = path.join(__dirname, '..', '..', 'images_status', status.images_status);
                    const imageBuffer = fs.readFileSync(imagePath);
                    status.images_status = `data:image/jpeg;base64,${imageBuffer.toString('base64')}`;
                } catch (error) {
                    console.error('Error reading status image:', error);
                    status.images_status = null;
                }
            }
        });

        res.status(200).json(results);
    });
};

// Post new status
exports.postStatus = (req, res) => {
    const { id_users, caption, images_status } = req.body;
    
    // Create images_status directory if it doesn't exist
    const statusDir = path.join(__dirname, '..', '..', 'images_status');
    if (!fs.existsSync(statusDir)) {
        fs.mkdirSync(statusDir, { recursive: true });
    }

    let finalCaption = caption || 'NoText';
    let finalImageName = 'NoImages';

    // If there's an image, process it
    if (images_status) {
        const base64Data = images_status.replace(/^data:image\/\w+;base64,/, '');
        const imageBuffer = Buffer.from(base64Data, 'base64');
        finalImageName = `${Date.now()}-status.jpg`;
        const imagePath = path.join(statusDir, finalImageName);
        
        try {
            fs.writeFileSync(imagePath, imageBuffer);
            finalCaption = ''; // Set caption to NoText when image is uploaded
        } catch (err) {
            console.error('Error saving image:', err);
            return res.status(500).json({ error: 'Error saving image' });
        }
    }

    const query = 'INSERT INTO status (id_users, caption, images_status, date) VALUES (?, ?, ?, NOW())';
    
    dbConnection.query(query, [id_users, finalCaption, finalImageName], (err, result) => {
        if (err) {
            // Delete uploaded file if database insert fails
            if (finalImageName !== 'NoImages') {
                const imagePath = path.join(statusDir, finalImageName);
                fs.unlinkSync(imagePath);
            }
            console.error('Error posting status:', err);
            res.status(500).json({ error: 'Error posting status' });
            return;
        }

        res.status(201).json({
            message: 'Status posted successfully',
            id_status: result.insertId,
            images_status: finalImageName !== 'NoImages' ? images_status : null
        });
    });
};
