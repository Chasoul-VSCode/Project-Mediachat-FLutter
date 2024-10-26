// controllers/ConnUsers.js
const dbConnection = require('../config/database');

// Create a new user
exports.createUser = (req, res) => {
    const { nomor_hp, username, password } = req.body;
    const query = 'INSERT INTO users (nomor_hp, username, password) VALUES (?, ?, ?)';
    dbConnection.query(query, [nomor_hp, username, password], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error creating user' });
        } else {
            res.status(201).json({ message: 'User created successfully', id_users: result.insertId });
        }
    });
};

// Read all users
exports.getAllUsers = (req, res) => {
    const query = 'SELECT id_users, nomor_hp, username FROM users';
    dbConnection.query(query, (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching users' });
        } else {
            res.status(200).json(results);
        }
    });
};

// Read a single user
exports.getUser = (req, res) => {
    const id_users = req.params.id_users;
    const query = 'SELECT id_users, nomor_hp, username FROM users WHERE id_users = ?';
    dbConnection.query(query, [id_users], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching user' });
        } else if (results.length === 0) {
            res.status(404).json({ message: 'User not found' });
        } else {
            res.status(200).json(results[0]);
        }
    });
};

// Update a user
exports.updateUser = (req, res) => {
    const id_users = req.params.id_users;
    const { nomor_hp, username, password } = req.body;
    const query = 'UPDATE users SET nomor_hp = ?, username = ?, password = ? WHERE id_users = ?';
    dbConnection.query(query, [nomor_hp, username, password, id_users], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error updating user' });
        } else if (result.affectedRows === 0) {
            res.status(404).json({ message: 'User not found' });
        } else {
            res.status(200).json({ message: 'User updated successfully' });
        }
    });
};

// Delete a user
exports.deleteUser = (req, res) => {
    const id_users = req.params.id_users;
    const query = 'DELETE FROM users WHERE id_users = ?';
    dbConnection.query(query, [id_users], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error deleting user' });
        } else if (result.affectedRows === 0) {
            res.status(404).json({ message: 'User not found' });
        } else {
            res.status(200).json({ message: 'User deleted successfully' });
        }
    });
};
