-- Add archived column to users table if it doesn't exist
-- Run this SQL script on your database

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE;

-- Create an index for better query performance
CREATE INDEX IF NOT EXISTS idx_users_archived ON users(archived);

-- Update existing users to have archived = false if NULL
UPDATE users SET archived = FALSE WHERE archived IS NULL;

