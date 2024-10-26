const mysql = require('mysql2');

const connection = mysql.createConnection({
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'Shacia1858',
    database: 'dbs_kokit'
});

module.exports = connection;
