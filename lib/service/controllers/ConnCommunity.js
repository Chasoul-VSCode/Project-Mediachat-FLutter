const dbConnection = require('../config/database');

// Get all communities
exports.getAllCommunities = (req, res) => {
    const query = `
        SELECT c.id_community, c.id_users, c.community_name, c.chat, c.date, c.member,
               u.username, u.images_profile
        FROM communities c
        JOIN users u ON c.id_users = u.id_users
        ORDER BY c.date DESC`;

    dbConnection.query(query, (err, results) => {
        if (err) {
            console.error('Error fetching communities:', err);
            res.status(500).json({ error: 'Error fetching communities' });
            return;
        }

        res.status(200).json(results);
    });
};

// Get communities by user ID
exports.getCommunitiesByUserId = (req, res) => {
    const { id_users } = req.params;

    const query = `
        SELECT c.id_community, c.id_users, c.community_name, c.chat, c.date, c.member,
               u.username, u.images_profile
        FROM communities c
        JOIN users u ON c.id_users = u.id_users
        WHERE c.id_users = ?
        ORDER BY c.date DESC`;

    dbConnection.query(query, [id_users], (err, results) => {
        if (err) {
            console.error('Error fetching user communities:', err);
            res.status(500).json({ error: 'Error fetching user communities' });
            return;
        }

        res.status(200).json(results);
    });
};

// Create new community
exports.createCommunity = (req, res) => {
    const { id_users, community_name } = req.body;

    if (!id_users || !community_name) {
        res.status(400).json({ error: 'id_users and community_name are required' });
        return;
    }

    const query = 'INSERT INTO communities (id_users, community_name, chat, member, date) VALUES (?, ?, ?, ?, NOW())';

    dbConnection.query(query, [id_users, community_name, '', id_users], (err, result) => {
        if (err) {
            console.error('Error creating community:', err);
            res.status(500).json({ error: 'Error creating community' });
            return;
        }

        res.status(201).json({
            message: 'Community created successfully',
            id_community: result.insertId,
            id_users,
            community_name,
            chat: '',
            member: id_users,
            date: new Date()
        });
    });
};
