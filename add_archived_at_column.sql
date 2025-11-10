-- Add archived_at column to users table for tracking when users were archived
-- This enables automatic permanent deletion after 30 days

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS archived_at TIMESTAMP;

-- Create an index for better query performance
CREATE INDEX IF NOT EXISTS idx_users_archived_at ON users(archived_at);

-- Update existing archived users to set archived_at to their updated_at timestamp
-- (assuming they were archived when updated_at was last changed)
UPDATE users 
SET archived_at = updated_at 
WHERE archived = true AND archived_at IS NULL;

