const mysql = require('mysql2');

const connection = mysql.createConnection({
    host: 'localhost',
    port: 3306,
    user: 'chasoulu_kokit',
    password: 'Shacia1858',
    database: 'chasoulu_kokit'
});

module.exports = connection;
