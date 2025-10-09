const {Client} = require('pg');
require('dotenv').config();

// For Local Database

/*const client = new Client({
    host: 'localhost',
    user: process.env.DB_USER,
    port: process.env.DB_PORT,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME
})*/

// For Remote Database (Supabase)

const client = new Client({
  connectionString: "postgresql://postgres.nacwxaebqxiihwgowaok:XmwcJTZ2QF0qSn6M@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres",
});

client.connect()
    .then(() => console.log('Connected to the database'))
    .catch(err => console.error('Connection error', err.stack));

module.exports = client;