const dbConnection = require('../config/database');

// Get all statuses
exports.getAllStatus = (req, res) => {
    const query = `
        SELECT s.id_status, s.id_users, s.caption, s.date,
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

        res.status(200).json(results);
    });
};

// Post new status
exports.postStatus = (req, res) => {
    const { id_users, caption } = req.body;
    
    if (!id_users || !caption) {
        res.status(400).json({ error: 'id_users and caption are required' });
        return;
    }

    const query = 'INSERT INTO status (id_users, caption, date) VALUES (?, ?, NOW())';
    
    dbConnection.query(query, [id_users, caption], (err, result) => {
        if (err) {
            console.error('Error posting status:', err);
            res.status(500).json({ error: 'Error posting status' });
            return;
        }

        res.status(201).json({
            message: 'Status posted successfully',
            id_status: result.insertId
        });
    });
};
