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

        // Insert into registrations table
        const registrationQuery = 'INSERT INTO registrations (nomor_hp, password) VALUES (?, ?)';
        dbConnection.query(registrationQuery, [nomor_hp, password], (err, registrationResult) => {
            if (err) {
                return dbConnection.rollback(() => {
                    res.status(500).json({ error: 'Error creating registration' });
                });
            }

            const id_registrations = registrationResult.insertId;

            // Insert into users table using id_registrations as id_users
            const userQuery = 'INSERT INTO users (id_users, nomor_hp, username, password) VALUES (?, ?, ?, ?)';
            dbConnection.query(userQuery, [id_registrations, nomor_hp, username, password], (err, userResult) => {
                if (err) {
                    return dbConnection.rollback(() => {
                        res.status(500).json({ error: 'Error creating user' });
                    });
                }

                // Commit the transaction
                dbConnection.commit((err) => {
                    if (err) {
                        return dbConnection.rollback(() => {
                            res.status(500).json({ error: 'Error committing transaction' });
                        });
                    }
                    res.status(201).json({ 
                        message: 'Registration and user created successfully', 
                        id_registrations: id_registrations,
                        id_users: id_registrations
                    });
                });
            });
        });
    });
};

// Read all registrations with corresponding user information
exports.getAllRegistrations = (req, res) => {
    const query = `
        SELECT 
            r.id_registrations, 
            r.nomor_hp, 
            r.password,
            u.id_users, 
            u.username,
            u.nomor_hp AS user_nomor_hp
        FROM registrations r
        LEFT JOIN users u ON r.id_registrations = u.id_users
    `;
    dbConnection.query(query, (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching registrations', details: err.message });
        } else {
            res.status(200).json({
                message: 'Registrations fetched successfully',
                data: results
            });
        }
    });
};
