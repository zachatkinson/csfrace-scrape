-- PostgreSQL Extensions Initialization
-- This script creates PostgreSQL extensions for the CSFrace scraping application

-- Enable UUID generation extension (commonly used for primary keys)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable advanced text search capabilities
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Enable query statistics collection (useful for performance monitoring)
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Enable JSON operations enhancement
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Log extension creation
DO $$
BEGIN
    RAISE NOTICE 'PostgreSQL extensions initialized successfully for CSFrace scraper';
END $$;