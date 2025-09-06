const {Client} = require('pg');

const client = new Client({
    host: 'localhost',
    user: 'glycel_yvon',
    port: 5432,
    password: 'pogiako10',
    database: 'fcm'
})

client.connect()
    .then(() => console.log('Connected to the database'))
    .catch(err => console.error('Connection error', err.stack));

module.exports = client;