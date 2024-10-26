// app.js
const express = require('express');
const ConnRoutes = require('./routes/ConnRoutes');
const UserRoutes = require('./routes/RoutesUsers');
const RegistrationsRoutes = require('./routes/RegistrationsRoutes');
const app = express();

// Middleware untuk mengurai JSON
app.use(express.json());

// Use the routes defined in ConnRoutes, ProductRoutes, UserRoutes, and RegistrationsRoutes
app.use('/api', ConnRoutes);
app.use('/api', UserRoutes);
app.use('/api', RegistrationsRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Internal Server Error' });
});

// Start the server
const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});
