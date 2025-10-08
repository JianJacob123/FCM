const {Client} = require('pg');
require('dotenv').config();

const client = new Client({
    connectionString: process.env.DATABASE_URL || "postgresql://postgres.nacwxaebqxiihwgowaok:XmwcJTZ2QF0qSn6M@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres",
});
  
client.connect()
    .then(() => console.log('Connected to the database'))
    .catch(err => console.error('Connection error', err.stack));

module.exports = client;