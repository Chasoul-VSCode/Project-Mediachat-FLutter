const dbPool = require('../config/database');

module.exports = {
    connDB: async (req, res) => {
        let connection;

        try {
            connection = await dbPool.getConnection();
            await connection.ping(); // Test the connection
            res.status(200).json({ message: 'Successfully connected to database' });
        } catch (err) {
            res.status(500).json({ error: 'Database connection error', details: err.message });
            console.error('Error connecting to database:', err);
        } finally {
            if (connection) connection.release(); // Ensure connection is released
        }
    }
};
