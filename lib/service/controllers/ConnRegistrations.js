// controllers/ConnRegistrations.js
const dbConnection = require('../config/database');

// Create a new registration and user
exports.createRegistration = (req, res) => {
    const { nomor_hp, password, username } = req.body;
    
    // Start a transaction
    dbConnection.beginTransaction((err) => {
        if (err) {
            return res.status(500).json({ error: 'Error starting transaction' });
        }

        // Insert into users table with default status 0 and default images_profile
        const userQuery = 'INSERT INTO users (nomor_hp, username, password, status, images_profile) VALUES (?, ?, ?, 0, "NoImages")';
        dbConnection.query(userQuery, [nomor_hp, username, password], (err, userResult) => {
            if (err) {
                return dbConnection.rollback(() => {
                    res.status(500).json({ error: 'Error creating user' });
                });
            }

            const id_users = userResult.insertId;

            // Commit the transaction
            dbConnection.commit((err) => {
                if (err) {
                    return dbConnection.rollback(() => {
                        res.status(500).json({ error: 'Error committing transaction' });
                    });
                }
                res.status(201).json({ 
                    message: 'User created successfully', 
                    id_users: id_users
                });
            });
        });
    });
};

// Read all users
exports.getAllRegistrations = (req, res) => {
    const query = 'SELECT id_users, nomor_hp, username, password, status, images_profile FROM users';
    dbConnection.query(query, (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching users', details: err.message });
        } else {
            res.status(200).json({
                message: 'Users fetched successfully',
                data: results
            });
        }
    });
};
