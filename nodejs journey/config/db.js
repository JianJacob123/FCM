const {Client} = require('pg');
require('dotenv').config();

const client = new Client({
    host: 'localhost',
    user: process.env.DB_USER,
    port: process.env.DB_PORT,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
})

client.connect()
    .then(() => console.log('Connected to the database'))
    .catch(err => console.error('Connection error', err.stack));

module.exports = client;