const client = require('./config/db');

async function addArchiveColumn() {
  try {
    console.log('Adding archived column to users table...');
    
    // Add the archived column
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE;
    `);
    console.log('✓ Added archived column');
    
    // Create index
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_users_archived ON users(archived);
    `);
    console.log('✓ Created index on archived column');
    
    // Update existing users
    await client.query(`
      UPDATE users SET archived = FALSE WHERE archived IS NULL;
    `);
    console.log('✓ Updated existing users');
    
    console.log('\n✅ Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  }
}

addArchiveColumn();

