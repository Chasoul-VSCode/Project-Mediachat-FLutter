const db = require('../config/database');

// Get all journals for a user
exports.getJournals = async (req, res) => {
    const userId = req.params.userId;
    try {
        const query = `
            SELECT j.id_journal, j.id_users, j.judul, j.isi, j.for_users, j.date, u.username
            FROM journals j
            LEFT JOIN users u ON j.id_users = u.id_users 
            WHERE j.id_users = ? OR FIND_IN_SET(?, j.for_users) > 0
            ORDER BY j.date DESC
        `;
        const [journals] = await db.execute(query, [userId, userId]);

        if (!journals || journals.length === 0) {
            return res.status(200).json({
                status: 'success',
                data: [],
                message: 'No journals found'
            });
        }

        res.status(200).json({
            status: 'success',
            data: journals
        });

    } catch (error) {
        console.error('Error fetching journals:', error);
        res.status(500).json({
            status: 'error',
            message: 'Error fetching journals from database',
            error: error.message
        });
    }
};

// Get all journals
exports.getAllJournals = async (req, res) => {
    try {
        const query = `
            SELECT j.id_journal, j.id_users, j.judul, j.isi, j.for_users, j.date, u.username
            FROM journals j
            LEFT JOIN users u ON j.id_users = u.id_users
            ORDER BY j.date DESC
        `;
        const [journals] = await db.execute(query);

        if (!journals || journals.length === 0) {
            return res.status(200).json({
                status: 'success',
                data: [],
                message: 'No journals found'
            });
        }

        res.status(200).json({
            status: 'success',
            data: journals
        });

    } catch (error) {
        console.error('Error fetching journals:', error);
        res.status(500).json({
            status: 'error',
            message: 'Error fetching journals from database',
            error: error.message
        });
    }
};

// Create new journal
exports.createJournal = async (req, res) => {
    const { id_users, judul, isi, for_users } = req.body;
    try {
        // Set default for_users to 0 if not provided
        const finalForUsers = for_users || '0';

        const query = `
            INSERT INTO journals (id_users, judul, isi, for_users, date)
            VALUES (?, ?, ?, ?, NOW())
        `;
        const [result] = await db.execute(query, [id_users, judul, isi, finalForUsers]);
        res.status(201).json({
            status: 'success',
            message: 'Journal created successfully',
            data: {
                journalId: result.insertId,
                id_users,
                judul,
                isi,
                for_users: finalForUsers
            }
        });
    } catch (error) {
        console.error('Error creating journal:', error);
        res.status(500).json({
            status: 'error',
            message: 'Error creating journal',
            error: error.message
        });
    }
};

// Get single journal by id
exports.getJournalById = async (req, res) => {
    const journalId = req.params.journalId;
    const userId = req.params.userId;
    try {
        const query = `
            SELECT j.id_journal, j.id_users, j.judul, j.isi, j.for_users, j.date, u.username
            FROM journals j
            LEFT JOIN users u ON j.id_users = u.id_users
            WHERE j.id_journal = ? AND (j.id_users = ? OR FIND_IN_SET(?, j.for_users) > 0)
        `;
        const [journals] = await db.execute(query, [journalId, userId, userId]);

        if (!journals || journals.length === 0) {
            return res.status(200).json({
                status: 'success',
                data: null,
                message: 'Journal not found'
            });
        }

        res.status(200).json({
            status: 'success',
            data: journals[0]
        });

    } catch (error) {
        console.error('Error fetching journal:', error);
        res.status(500).json({
            status: 'error',
            message: 'Error fetching journal',
            error: error.message
        });
    }
};
