// controllers/ConnUsers.js
const dbConnection = require('../config/database');
const fs = require('fs');
const path = require('path');

// Read all users

exports.getAllUsers = (req, res) => {
    const query = 'SELECT id_users, nomor_hp, username, password, images_profile FROM users';
    
    dbConnection.query(query, (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Error fetching users' });
        }

        // Proses setiap pengguna untuk menambahkan gambar profil
        const usersWithImages = results.map(user => {
            if (user.images_profile) {
                try {
                    // Tentukan path lengkap untuk gambar profil
                    const profileDir = path.join(__dirname, '..', '..', 'images'); 
                    // Baca file gambar
                    const imagePath = path.join(profileDir, user.images_profile);
                    const imageBuffer = fs.readFileSync(imagePath);
                    const base64Image = imageBuffer.toString('base64');
                    user.images_profile = `data:image/jpeg;base64,${base64Image}`;
                } catch (error) {
                    console.error('Error reading profile image:', error);
                    user.images_profile = null; // Atur ke null jika terjadi kesalahan
                }
            } else {
                user.images_profile = null; // Jika tidak ada gambar, set ke null
            }
            return user; // Kembalikan objek pengguna yang sudah dimodifikasi
        });

        res.status(200).json(usersWithImages); // Kirim respons dengan data pengguna
    });
};


// Read a single user
exports.getUser = (req, res) => {
    const id_users = req.params.id_users;
    const query = 'SELECT id_users, nomor_hp, username, password, images_profile FROM users WHERE id_users = ?';

    dbConnection.query(query, [id_users], (err, results) => {
        if (err) {
            return res.status(500).json({ error: 'Error fetching user' });
        } 
        if (results.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        } 

        const user = results[0];
        if (user.images_profile) {
            try {
                // Tentukan direktori di mana gambar profil disimpan
                const profileDir = path.join(__dirname, '..', '..', 'images');
                // Baca file gambar
                const imagePath = path.join(profileDir, user.images_profile);
                const imageBuffer = fs.readFileSync(imagePath);
                const base64Image = imageBuffer.toString('base64');
                user.images_profile = `data:image/jpeg;base64,${base64Image}`;
            } catch (error) {
                console.error('Error reading profile image:', error);
                user.images_profile = null; // Atur ke null jika terjadi kesalahan
            }
        }
        
        // Kirim respons dengan data pengguna
        res.status(200).json(user);
    });
};


// Function to update user profile
exports.updateUser = (req, res) => {
  const id_users = req.params.id_users;
  const { username, images_profile } = req.body;

  // Define the directory for saving profile images
  const profileDir = path.join(__dirname, '..', '..', 'images');

  // Ensure the directory exists
  fs.mkdir(profileDir, { recursive: true }, (err) => {
    if (err) {
      console.error('Error creating directory:', err);
      return res.status(500).json({ error: 'Error creating directory' });
    }

    if (images_profile) {
      const fileName = `${Date.now()}-profile.jpg`; // Generate unique file name
      const filePath = path.join(profileDir, fileName);

      // Process the base64 image data
      const base64Data = images_profile.replace(/^data:image\/\w+;base64,/, '');
      const imageBuffer = Buffer.from(base64Data, 'base64');

      // Save the image
      fs.writeFile(filePath, imageBuffer, (err) => {
        if (err) {
          console.error('Error saving image:', err);
          return res.status(500).json({ error: 'Error saving image' });
        }

        // Save only the file name to the database
        const query = 'UPDATE users SET username = ?, images_profile = ? WHERE id_users = ?';
        dbConnection.query(query, [username, fileName, id_users], (err, result) => {
          if (err) {
            console.error('Error updating user:', err);
            return res.status(500).json({ error: 'Error updating user' });
          } else if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User not found' });
          } else {
            res.status(200).json({ 
              message: 'User and image updated successfully',
              imagePath: fileName, // Send the filename back as confirmation
            });
          }
        });
      });
    } else {
      // If no image provided, just update username
      const query = 'UPDATE users SET username = ? WHERE id_users = ?';
      dbConnection.query(query, [username, id_users], (err, result) => {
        if (err) {
          console.error('Error updating user without image:', err);
          return res.status(500).json({ error: 'Error updating user' });
        } else if (result.affectedRows === 0) {
          return res.status(404).json({ message: 'User not found' });
        } else {
          res.status(200).json({ message: 'User updated successfully' });
        }
      });
    }
  });
};

// Delete a user
exports.deleteUser = (req, res) => {
    const id_users = req.params.id_users;
    const query = 'DELETE FROM users WHERE id_users = ?';
    dbConnection.query(query, [id_users], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error deleting user' });
        } else if (result.affectedRows === 0) {
            res.status(404).json({ message: 'User not found' });
        } else {
            res.status(200).json({ message: 'User deleted successfully' });
        }
    });
};

// Login user by phone number
exports.loginUser = (req, res) => {
    const { nomor_hp, password } = req.body;
    const query = 'SELECT id_users, nomor_hp, username, password, images_profile FROM users WHERE nomor_hp = ? AND password = ?';
    dbConnection.query(query, [nomor_hp, password], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error during login' });
        } else if (results.length === 0) {
            res.status(401).json({ message: 'Invalid phone number or password' });
        } else {
            const user = results[0];
            if (user.images_profile) {
                try {
                    const profileDir = path.join(__dirname, '..', '..', 'images');
                    const imagePath = path.join(profileDir, user.images_profile);
                    const imageBuffer = fs.readFileSync(imagePath);
                    const base64Image = imageBuffer.toString('base64');
                    user.images_profile = `data:image/jpeg;base64,${base64Image}`;
                } catch (error) {
                    console.error('Error reading profile image:', error);
                    user.images_profile = null;
                }
            }
            // Update status to 1 when user logs in
            const updateStatusQuery = 'UPDATE users SET status = 1 WHERE id_users = ?';
            dbConnection.query(updateStatusQuery, [user.id_users], (updateErr) => {
                if (updateErr) {
                    res.status(500).json({ error: 'Error updating login status' });
                } else {
                    res.status(200).json({
                        message: 'Login successful',
                        user: user
                    });
                }
            });
        }
    });
};

// Get user profile image
exports.getUserProfileImage = (req, res) => {
    const id_users = req.params.id_users;
    const query = 'SELECT images_profile FROM users WHERE id_users = ?';
    
    dbConnection.query(query, [id_users], (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching profile image' });
        } else if (results.length === 0) {
            res.status(404).json({ message: 'User not found' });
        } else {
            const user = results[0];
            if (user.images_profile) {
                try {
                    const profileDir = path.join(__dirname, '..', '..', 'images');
                    const imagePath = path.join(profileDir, user.images_profile);
                    const imageBuffer = fs.readFileSync(imagePath);
                    const base64Image = imageBuffer.toString('base64');
                    res.status(200).json({
                        images_profile: `data:image/jpeg;base64,${base64Image}`
                    });
                } catch (error) {
                    console.error('Error reading profile image:', error);
                    res.status(404).json({ message: 'Profile image not found' });
                }
            } else {
                res.status(404).json({ message: 'No profile image set' });
            }
        }
    });
};


// Logout user
exports.logoutUser = (req, res) => {
    const id_users = req.params.id_users;
    const query = 'UPDATE users SET status = 0 WHERE id_users = ?';
    dbConnection.query(query, [id_users], (err, result) => {
        if (err) {
            res.status(500).json({ error: 'Error during logout' });
        } else if (result.affectedRows === 0) {
            res.status(404).json({ message: 'User not found' });
        } else {
            res.status(200).json({ message: 'Logout successful' });
        }
    });
};
