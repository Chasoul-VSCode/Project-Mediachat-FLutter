// app.js
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const ConnRoutes = require('./routes/ConnRoutes');
const UserRoutes = require('./routes/RoutesUsers');
const RegistrationsRoutes = require('./routes/RegistrationsRoutes');
const ChatRoutes = require('./routes/ChatRoutes');
const GroupRoutes = require('./routes/GroupRoutes'); 
const StatusRoutes = require('./routes/StatusRoutes');
const CommunityRoutes = require('./routes/CommunityRoutes');
const JournalRoutes = require('./routes/JournalRoutes');
const EventRoutes = require('./routes/EventRoutes');
const app = express();

// Enable CORS
app.use(cors());

// Configure JSON parsing middleware with size limits
app.use(express.json({limit: '50mb'}));
app.use(express.urlencoded({limit: '50mb', extended: true}));
app.use(bodyParser.json({limit: '50mb'}));
app.use(bodyParser.urlencoded({limit: '50mb', extended: true}));

// Static files middleware
app.use('/images', express.static('images'));

// API Routes
app.use('/api', ConnRoutes);
app.use('/api', UserRoutes);
app.use('/api', RegistrationsRoutes);
app.use('/api', ChatRoutes);
app.use('/api', GroupRoutes);
app.use('/api', StatusRoutes); // Added StatusRoutes
app.use('/api', CommunityRoutes);
app.use('/api', JournalRoutes);
app.use('/api', EventRoutes);


// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        status: 'error',
        message: 'Internal Server Error',
        error: err.message,
        stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
});

// Start server
const port = process.env.PORT || 3000;
app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
    console.log('Press CTRL+C to stop server');
});
