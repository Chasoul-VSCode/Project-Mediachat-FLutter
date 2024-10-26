// routes/RoutesUsers.js
const express = require('express');
const router = express.Router();
const ConnUsers = require('../controllers/ConnUsers');

router.post('/users', ConnUsers.createUser);
router.get('/users', ConnUsers.getAllUsers);
router.get('/users/:id_users', ConnUsers.getUser);
router.put('/users/:id_users', ConnUsers.updateUser);
router.delete('/users/:id_users', ConnUsers.deleteUser);

module.exports = router;
