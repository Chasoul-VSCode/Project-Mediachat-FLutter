// controllers/ConnUsers.js
const dbConnection = require('../config/database');

// Read all users
exports.getAllUsers = (req, res) => {
    const query = 'SELECT id_users, nomor_hp, username, password FROM users';
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
    const query = 'SELECT id_users, nomor_hp, username, password FROM users WHERE id_users = ?';
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
    const query = 'UPDATE users SET username = ?WHERE id_users = ?';
    dbConnection.query(query, [username, id_users], (err, result) => {
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

// Login user by phone number
exports.loginUser = (req, res) => {
    const { nomor_hp, password } = req.body;
    const query = 'SELECT id_users, nomor_hp, username, password FROM users WHERE nomor_hp = ? AND password = ?';
    dbConnection.query(query, [nomor_hp, password], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error during login' });
        } else if (results.length === 0) {
            res.status(401).json({ message: 'Invalid phone number or password' });
        } else {
            res.status(200).json({
                message: 'Login successful',
                user: results[0]
            });
        }
    });
};
