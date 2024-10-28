const dbConnection = require('../config/database');

// Get all groups
exports.getAllGroups = (req, res) => {
    const query = 'SELECT name_groups FROM groups';
    dbConnection.query(query, (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching groups', details: err.message });
        } else {
            res.status(200).json({
                message: 'Groups fetched successfully',
                data: result
            });
        }
    });
};

// Get groups by user id 
exports.getGroupsByUserId = (req, res) => {
    const id_users = req.params.id_users;
    const query = 'SELECT name_groups FROM groups WHERE id_users = ?';
    dbConnection.query(query, [id_users], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching groups', details: err.message });
        } else {
            res.status(200).json({
                message: 'Groups fetched successfully',
                data: result
            });
        }
    });
};

// Get group by id_groups
exports.getGroupById = (req, res) => {
    const id_groups = req.params.id_groups;
    const query = 'SELECT name_groups FROM groups WHERE id_groups = ?';
    dbConnection.query(query, [id_groups], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching group', details: err.message });
        } else if (result.length === 0) {
            res.status(404).json({ message: 'Group not found' });
        } else {
            res.status(200).json({
                message: 'Group fetched successfully',
                data: result[0]
            });
        }
    });
};

// Create a new group
exports.createGroup = (req, res) => {
    const { id_users, name_groups } = req.body;
    const jakartaTime = new Date().toLocaleTimeString('en-US', { 
        hour12: false,
        timeZone: 'Asia/Jakarta'
    });
    const query = 'INSERT INTO groups (id_users, name_groups, date) VALUES (?, ?, ?)';
    dbConnection.query(query, [id_users, name_groups, jakartaTime], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error creating group', details: err.message });
        } else {
            res.status(201).json({
                message: 'Group created successfully',
                data: {
                    id_groups: result.insertId,
                    id_users,
                    name_groups,
                    date: jakartaTime
                }
            });
        }
    });
};

// Update a group
exports.updateGroup = (req, res) => {
    const id_groups = req.params.id_groups;
    const { chat, name_groups } = req.body;
    const date = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const query = 'UPDATE groups SET chat = ?, name_groups = ?, date = ? WHERE id_groups = ?';
    dbConnection.query(query, [chat, name_groups, date, id_groups], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error updating group', details: err.message });
        } else if (result.affectedRows === 0) {
            res.status(404).json({ message: 'Group not found' });
        } else {
            res.status(200).json({
                message: 'Group updated successfully',
                data: {
                    id_groups,
                    chat,
                    name_groups,
                    date
                }
            });
        }
    });
};

// Delete a group
exports.deleteGroup = (req, res) => {
    const id_groups = req.params.id_groups;
    const query = 'DELETE FROM groups WHERE id_groups = ?';
    dbConnection.query(query, [id_groups], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error deleting group', details: err.message });
        } else if (result.affectedRows === 0) {
            res.status(404).json({ message: 'Group not found' });
        } else {
            res.status(200).json({
                message: 'Group deleted successfully'
            });
        }
    });
};
