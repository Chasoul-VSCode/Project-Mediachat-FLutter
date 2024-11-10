const db = require('../config/database');

// Get all events
exports.getAllEvents = (req, res) => {
    const query = `
        SELECT e.id_event, e.id_users, e.isi, e.date, u.username
        FROM events e
        LEFT JOIN users u ON e.id_users = u.id_users
        ORDER BY e.date DESC
    `;
    db.query(query, (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Error fetching events', details: err.message });
        } else {
            // Convert any binary data to base64 if needed
            const processedResults = results.map(result => {
                // Add any data processing here if needed
                return result;
            });

            res.status(200).json({
                message: 'Events fetched successfully',
                data: processedResults
            });
        }
    });
};

// Get all events with user details
exports.getAllEventsWithUsers = async (req, res) => {
  try {
    const query = `
      SELECT e.id_event, e.id_users, e.isi, e.date, u.username 
      FROM events e
      LEFT JOIN users u ON e.id_users = u.id_users
      ORDER BY e.date DESC
    `;
    const [events] = await db.execute(query);
    
    // Ensure events is an array before checking length
    const eventsArray = Array.isArray(events) ? events : [];
    
    if (eventsArray.length === 0) {
      return res.status(200).json({ // Changed to 200 to indicate success even with empty results
        status: 'success',
        data: [],
        message: 'No events found'
      });
    }

    res.status(200).json({
      status: 'success',
      data: eventsArray
    });

  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({
      status: 'error',
      message: 'Error fetching events from database',
      error: error.message 
    });
  }
};


// Get single event by id
exports.getEventById = async (req, res) => {
  const eventId = req.params.eventId;
  try {
    const query = `
      SELECT e.id_event, e.id_users, e.isi, e.date, u.username
      FROM events e
      LEFT JOIN users u ON e.id_users = u.id_users
      WHERE e.id_event = ?
    `;
    const [events] = await db.execute(query, [eventId]);
    
    if (!events || events.length === 0) {
      return res.status(200).json({ // Changed to 200 to indicate success even when not found
        status: 'success',
        data: null,
        message: 'Event not found'
      });
    }

    res.status(200).json({
      status: 'success',
      data: events[0]
    });

  } catch (error) {
    console.error('Error fetching event:', error);
    res.status(500).json({
      status: 'error', 
      message: 'Error fetching event',
      error: error.message
    });
  }
};

// Create new event
exports.createEvent = async (req, res) => {
  const { id_users, isi, date } = req.body;
  try {
    const query = `
      INSERT INTO events (id_users, isi, date)
      VALUES (?, ?, ?)
    `;
    const [result] = await db.execute(query, [id_users, isi, date]);
    
    res.status(201).json({
      status: 'success',
      message: 'Event created successfully',
      data: {
        eventId: result.insertId,
        id_users,
        isi,
        date
      }
    });
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({
      status: 'error',
      message: 'Error creating event',
      error: error.message
    });
  }
};
