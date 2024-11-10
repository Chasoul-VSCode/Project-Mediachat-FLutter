const express = require('express');
const router = express.Router();
const journalController = require('../controllers/ConnJournal');

// Get all journals for a user
router.get('/journals/:userId', journalController.getJournals);

// Get all journals
router.get('/journals', journalController.getAllJournals);

// Get single journal by id
router.get('/journals/:userId/:journalId', journalController.getJournalById);

// Create new journal
router.post('/journals', journalController.createJournal);

module.exports = router;
