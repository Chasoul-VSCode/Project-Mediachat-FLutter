const express = require('express');
const path = require('path');
const app = express();

// Adjust the path to account for the correct location
const routesDatabasePath = path.join(__dirname, 'Routes', 'RoutesDatabase.js');
console.log('Attempting to require:', routesDatabasePath);

// Use try-catch to handle potential module loading errors
let routesDatabase;
try {
    routesDatabase = require(routesDatabasePath);
} catch (error) {
    console.error('Error loading RoutesDatabase module:', error);
    process.exit(1); // Exit the process if the module can't be loaded
}

// Middleware for parsing JSON
app.use(express.json());

// Use the routes
app.use('/api', routesDatabase);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal Server Error' });
});

// Start the server
const port = process.env.PORT || 3000;
const server = app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
    });
});
