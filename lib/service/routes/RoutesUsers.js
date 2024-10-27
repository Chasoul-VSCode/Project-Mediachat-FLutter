// routes/RoutesUsers.js
const express = require('express');
const router = express.Router();
const ConnUsers = require('../controllers/ConnUsers');

// Define routes
router.get('/users', ConnUsers.getAllUsers);
router.get('/users/:id_users', ConnUsers.getUser);
router.put('/users/:id_users', ConnUsers.updateUser);
router.delete('/users/:id_users', ConnUsers.deleteUser);
router.post('/login', (req, res) => {
  const { nomor_hp, password } = req.body;
  ConnUsers.loginUser(req, res);
});

// Export the router
module.exports = router;
