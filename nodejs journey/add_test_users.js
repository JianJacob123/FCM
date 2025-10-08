const { Client } = require('pg');
require('dotenv').config();

const client = new Client({
    connectionString: process.env.DATABASE_URL || "postgresql://postgres.nacwxaebqxiihwgowaok:XmwcJTZ2QF0qSn6M@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres",
});

async function addTestUsers() {
    try {
        await client.connect();
        console.log('Connected to database');

        // Add test drivers
        const drivers = [
            { name: 'John Driver', username: 'john_driver', password: 'password123' },
            { name: 'Jane Driver', username: 'jane_driver', password: 'password123' },
            { name: 'Mike Driver', username: 'mike_driver', password: 'password123' }
        ];

        // Add test conductors
        const conductors = [
            { name: 'Alice Conductor', username: 'alice_conductor', password: 'password123' },
            { name: 'Bob Conductor', username: 'bob_conductor', password: 'password123' },
            { name: 'Carol Conductor', username: 'carol_conductor', password: 'password123' }
        ];

        // Insert drivers
        for (const driver of drivers) {
            await client.query(`
                INSERT INTO users (full_name, user_role, username, user_pass, active, created_at, updated_at)
                VALUES ($1, $2, $3, $4, true, NOW(), NOW())
                ON CONFLICT (username) DO NOTHING
            `, [driver.name, 'Driver', driver.username, driver.password]);
            console.log(`Added driver: ${driver.name}`);
        }

        // Insert conductors
        for (const conductor of conductors) {
            await client.query(`
                INSERT INTO users (full_name, user_role, username, user_pass, active, created_at, updated_at)
                VALUES ($1, $2, $3, $4, true, NOW(), NOW())
                ON CONFLICT (username) DO NOTHING
            `, [conductor.name, 'Conductor', conductor.username, conductor.password]);
            console.log(`Added conductor: ${conductor.name}`);
        }

        console.log('Test users added successfully!');
        
        // Verify the users were added
        const driverCount = await client.query("SELECT COUNT(*) FROM users WHERE user_role = 'Driver' AND active = true");
        const conductorCount = await client.query("SELECT COUNT(*) FROM users WHERE user_role = 'Conductor' AND active = true");
        
        console.log(`Total active drivers: ${driverCount.rows[0].count}`);
        console.log(`Total active conductors: ${conductorCount.rows[0].count}`);

    } catch (error) {
        console.error('Error adding test users:', error);
    } finally {
        await client.end();
    }
}

addTestUsers();
