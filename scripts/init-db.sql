-- CSFrace Scrape Database Schema Initialization (Production)
-- WordPress to Shopify Converter Database Structure

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For better indexing

-- Create enum types for consistent data
DO $$ BEGIN
    CREATE TYPE job_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE job_type AS ENUM ('single', 'batch', 'scheduled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE content_type AS ENUM ('wordpress', 'shopify', 'generic');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE export_format AS ENUM ('html', 'json', 'markdown', 'csv');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- NOTE: Table creation has been moved to Alembic migrations
-- This script now only handles database extensions and enum types
-- Tables, indexes, and triggers are created by: alembic upgrade head
--
-- Alembic migrations ensure proper version tracking and idempotent schema changes
-- See: backend/alembic/versions/ for migration files

-- Database initialization complete
DO $$
BEGIN
    RAISE NOTICE 'Database extensions and enum types initialized successfully!';
    RAISE NOTICE 'Extensions: uuid-ossp, pg_trgm, btree_gin';
    RAISE NOTICE 'Enum types: job_status, job_type, content_type, export_format';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables will be created by Alembic migrations during backend startup';
    RAISE NOTICE 'See: backend/alembic/versions/ for schema definitions';
END $$;