// app.js
const express = require('express');
const ConnRoutes = require('./routes/ConnRoutes');
const UserRoutes = require('./routes/RoutesUsers');
const RegistrationsRoutes = require('./routes/RegistrationsRoutes');
const ChatRoutes = require('./routes/ChatRoutes');
const GroupRoutes = require('./routes/GroupRoutes');
const app = express();

// Middleware for parsing JSON
app.use(express.json());

// Tambahkan limit untuk JSON body parser
app.use(express.json({limit: '50mb'}));
app.use(express.urlencoded({limit: '50mb', extended: true}));

// Tambahkan ini jika menggunakan body-parser
const bodyParser = require('body-parser');
app.use(bodyParser.json({limit: '50mb'}));
app.use(bodyParser.urlencoded({limit: '50mb', extended: true}));

// Use the routes
app.use('/api', ConnRoutes);
app.use('/api', UserRoutes);
app.use('/api', RegistrationsRoutes);
app.use('/api', ChatRoutes);
app.use('/api', GroupRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        status: 'error',
        message: 'Internal Server Error',
        error: err.message,
        stack: err.stack,
        requireStack: err.requireStack
    });
});

// Start the server
const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
    console.log('Press CTRL+C to stop the server');
});
