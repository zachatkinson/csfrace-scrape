-- CSFrace Scrape Database Schema Initialization
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

-- Jobs table: Core table for tracking all conversion jobs
CREATE TABLE IF NOT EXISTS jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_type job_type NOT NULL DEFAULT 'single',
    status job_status NOT NULL DEFAULT 'pending',
    source_url TEXT NOT NULL,
    target_format export_format NOT NULL DEFAULT 'html',
    priority INTEGER DEFAULT 5 CHECK (priority >= 1 AND priority <= 10),
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    
    -- Configuration and results
    options JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Performance metrics
    processing_time_ms INTEGER,
    download_size_bytes BIGINT,
    output_size_bytes BIGINT
);

-- Batches table: For grouping multiple jobs together
CREATE TABLE IF NOT EXISTS batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status job_status NOT NULL DEFAULT 'pending',
    total_jobs INTEGER DEFAULT 0,
    completed_jobs INTEGER DEFAULT 0,
    failed_jobs INTEGER DEFAULT 0,
    
    -- Processing configuration
    concurrent_limit INTEGER DEFAULT 5,
    rate_limit_per_second INTEGER DEFAULT 10,
    
    -- Metadata
    options JSONB DEFAULT '{}',
    statistics JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add batch relationship to jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES batches(id) ON DELETE CASCADE;

-- Content table: Stores the actual converted content
CREATE TABLE IF NOT EXISTS content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    content_type content_type NOT NULL,
    
    -- Content data
    title VARCHAR(500),
    slug VARCHAR(500),
    html_content TEXT,
    markdown_content TEXT,
    json_content JSONB,
    
    -- SEO metadata
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT[],
    
    -- WordPress specific fields
    wordpress_id INTEGER,
    wordpress_categories TEXT[],
    wordpress_tags TEXT[],
    wordpress_author VARCHAR(255),
    
    -- Shopify specific fields
    shopify_handle VARCHAR(255),
    shopify_template_suffix VARCHAR(100),
    shopify_published BOOLEAN DEFAULT true,
    
    -- Timestamps
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Images table: Tracks all images found and downloaded
CREATE TABLE IF NOT EXISTS images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID NOT NULL REFERENCES content(id) ON DELETE CASCADE,
    
    -- Image locations
    original_url TEXT NOT NULL,
    local_path TEXT,
    cdn_url TEXT,
    filename VARCHAR(500),
    
    -- Image metadata
    mime_type VARCHAR(100),
    size_bytes BIGINT,
    width INTEGER,
    height INTEGER,
    alt_text TEXT,
    caption TEXT,
    
    -- Processing status
    downloaded BOOLEAN DEFAULT false,
    optimized BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Cache table: For caching scraped pages
CREATE TABLE IF NOT EXISTS cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key VARCHAR(500) UNIQUE NOT NULL,
    cache_value TEXT,
    content_type VARCHAR(100),
    
    -- Source information
    url TEXT,
    headers JSONB,
    
    -- Cache management
    expires_at TIMESTAMP WITH TIME ZONE,
    hit_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Audit log: Track all system operations
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Event information
    event_type VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    
    -- Context
    user_id VARCHAR(255),
    session_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    
    -- Event details
    action VARCHAR(100) NOT NULL,
    details JSONB DEFAULT '{}',
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Performance metrics: Track system performance
CREATE TABLE IF NOT EXISTS metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Metric information
    metric_name VARCHAR(255) NOT NULL,
    metric_value NUMERIC,
    metric_unit VARCHAR(50),
    
    -- Related entities
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES batches(id) ON DELETE CASCADE,
    
    -- Additional context
    labels JSONB DEFAULT '{}',
    
    -- Timestamp
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for optimal query performance

-- Jobs indexes
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_batch_id ON jobs(batch_id);
CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON jobs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_source_url ON jobs(source_url);
CREATE INDEX IF NOT EXISTS idx_jobs_metadata ON jobs USING gin(metadata);

-- Batches indexes
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_created_at ON batches(created_at DESC);

-- Content indexes
CREATE INDEX IF NOT EXISTS idx_content_job_id ON content(job_id);
CREATE INDEX IF NOT EXISTS idx_content_slug ON content(slug);
CREATE INDEX IF NOT EXISTS idx_content_title ON content(title);
CREATE INDEX IF NOT EXISTS idx_content_published_at ON content(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_wordpress_id ON content(wordpress_id);
CREATE INDEX IF NOT EXISTS idx_content_shopify_handle ON content(shopify_handle);
CREATE INDEX IF NOT EXISTS idx_content_json ON content USING gin(json_content);

-- Full text search index for content
CREATE INDEX IF NOT EXISTS idx_content_search ON content USING gin(
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(html_content, ''))
);

-- Images indexes
CREATE INDEX IF NOT EXISTS idx_images_content_id ON images(content_id);
CREATE INDEX IF NOT EXISTS idx_images_original_url ON images(original_url);
CREATE INDEX IF NOT EXISTS idx_images_downloaded ON images(downloaded);

-- Cache indexes
CREATE INDEX IF NOT EXISTS idx_cache_key ON cache(cache_key);
CREATE INDEX IF NOT EXISTS idx_cache_expires_at ON cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_cache_url ON cache(url);

-- Audit log indexes
CREATE INDEX IF NOT EXISTS idx_audit_event_type ON audit_log(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_created_at ON audit_log(created_at DESC);

-- Metrics indexes
CREATE INDEX IF NOT EXISTS idx_metrics_name ON metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_job_id ON metrics(job_id);
CREATE INDEX IF NOT EXISTS idx_metrics_labels ON metrics USING gin(labels);

-- Create automatic update trigger for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_batches_updated_at ON batches;
CREATE TRIGGER update_batches_updated_at BEFORE UPDATE ON batches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_content_updated_at ON content;
CREATE TRIGGER update_content_updated_at BEFORE UPDATE ON content
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_images_updated_at ON images;
CREATE TRIGGER update_images_updated_at BEFORE UPDATE ON images
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create useful views for querying

-- View: Currently active jobs
CREATE OR REPLACE VIEW active_jobs AS
SELECT 
    j.id,
    j.job_type,
    j.status,
    j.source_url,
    j.target_format,
    j.created_at,
    j.started_at,
    b.name as batch_name
FROM jobs j
LEFT JOIN batches b ON j.batch_id = b.id
WHERE j.status IN ('pending', 'processing')
ORDER BY j.priority DESC, j.created_at ASC;

-- View: Job statistics by day
CREATE OR REPLACE VIEW job_statistics AS
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_jobs,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_jobs,
    COUNT(*) FILTER (WHERE status = 'failed') as failed_jobs,
    AVG(processing_time_ms) FILTER (WHERE status = 'completed') as avg_processing_time,
    SUM(download_size_bytes) FILTER (WHERE status = 'completed') as total_download_size,
    SUM(output_size_bytes) FILTER (WHERE status = 'completed') as total_output_size
FROM jobs
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- View: Content with related data
CREATE OR REPLACE VIEW content_summary AS
SELECT 
    c.id,
    c.title,
    c.slug,
    c.content_type,
    j.source_url,
    j.status as job_status,
    COUNT(DISTINCT i.id) as image_count,
    c.created_at
FROM content c
JOIN jobs j ON c.job_id = j.id
LEFT JOIN images i ON i.content_id = c.id
GROUP BY c.id, c.title, c.slug, c.content_type, j.source_url, j.status, c.created_at
ORDER BY c.created_at DESC;

-- Utility functions

-- Function: Clean expired cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM cache WHERE expires_at < CURRENT_TIMESTAMP;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function: Get job statistics for a time range
CREATE OR REPLACE FUNCTION get_job_stats(time_range INTERVAL DEFAULT '7 days')
RETURNS TABLE(
    total_jobs BIGINT,
    completed_jobs BIGINT,
    failed_jobs BIGINT,
    pending_jobs BIGINT,
    avg_processing_time NUMERIC,
    success_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_jobs,
        COUNT(*) FILTER (WHERE status = 'completed')::BIGINT as completed_jobs,
        COUNT(*) FILTER (WHERE status = 'failed')::BIGINT as failed_jobs,
        COUNT(*) FILTER (WHERE status = 'pending')::BIGINT as pending_jobs,
        AVG(processing_time_ms)::NUMERIC as avg_processing_time,
        (COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / NULLIF(COUNT(*), 0) * 100)::NUMERIC as success_rate
    FROM jobs
    WHERE created_at >= CURRENT_TIMESTAMP - time_range;
END;
$$ LANGUAGE plpgsql;

-- Database initialization complete
DO $$
BEGIN
    RAISE NOTICE 'Database schema initialized successfully!';
    RAISE NOTICE 'Tables created: jobs, batches, content, images, cache, audit_log, metrics';
    RAISE NOTICE 'Views created: active_jobs, job_statistics, content_summary';
    RAISE NOTICE 'Functions created: cleanup_expired_cache, get_job_stats';
END $$;