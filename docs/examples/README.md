# Batch Upload Examples

This directory contains example files showing the supported formats for batch URL processing in CSFrace Scrape.

## Supported File Formats

The batch upload feature supports three file formats:

### 1. Plain Text (.txt)

**File:** [`batch-urls.txt`](./batch-urls.txt)

The simplest format - just one URL per line:

```
https://csfrace.com/blog/post-1
https://csfrace.com/blog/post-2
https://csfrace.com/blog/post-3
```

**Best for:**
- Quick manual lists
- Copy/paste from spreadsheets
- Simple batch jobs

### 2. CSV (.csv)

**File:** [`batch-urls.csv`](./batch-urls.csv)

Standard CSV format with a header row:

```csv
url
https://csfrace.com/blog/post-1
https://csfrace.com/blog/post-2
https://csfrace.com/blog/post-3
```

**Best for:**
- Exporting from Excel/Google Sheets
- Adding metadata in future versions
- Structured data management

### 3. JSON (.json)

**File:** [`batch-urls.json`](./batch-urls.json)

JSON array of URL strings:

```json
[
  "https://csfrace.com/blog/post-1",
  "https://csfrace.com/blog/post-2",
  "https://csfrace.com/blog/post-3"
]
```

**Best for:**
- API integrations
- Programmatic batch creation
- Complex automation workflows

## Usage Instructions

### Via Web Interface

1. Navigate to the scraper interface
2. Click **"Switch to Batch Mode"**
3. Either:
   - **Paste URLs** directly into the text area (one per line)
   - **Upload a file** by clicking the upload area or dragging and dropping
4. Click **"Process X URLs"** to start the batch

### Via API

```bash
# Using curl with JSON
curl -X POST http://localhost:8000/batches \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Batch Job",
    "urls": [
      "https://csfrace.com/blog/post-1",
      "https://csfrace.com/blog/post-2"
    ]
  }'

# Using curl with file upload
curl -X POST http://localhost:8000/batches/upload \
  -F "file=@batch-urls.csv" \
  -F "name=My Batch Job"
```

## URL Requirements

**Valid URLs must:**
- Start with `http://` or `https://`
- Be publicly accessible
- Point to WordPress blog posts or pages
- Not be password protected (unless credentials are configured)

**Examples of valid URLs:**
```
✅ https://csfrace.com/blog/my-post
✅ https://blog.example.com/2024/01/article
✅ http://wordpress-site.org/category/post-slug
```

**Examples of invalid URLs:**
```
❌ csfrace.com/blog/post (missing protocol)
❌ file:///local/path/file.html (not HTTP/HTTPS)
❌ https://csfrace.com (homepage, not a post)
```

## Batch Processing Limits

- **Maximum URLs per batch:** 100 (configurable)
- **Concurrent processing:** 3-5 URLs at a time (configurable)
- **Timeout per URL:** 5 minutes (configurable)
- **Retry attempts:** 2 retries on failure (configurable)

## Output Structure

When you process a batch, each URL gets its own directory:

```
batch_output/
├── csfrace-com_how-to-prepare-for-race-day/
│   ├── metadata.txt
│   ├── converted_content.html
│   ├── shopify_ready_content.html
│   └── images/
├── csfrace-com_nutrition-tips-for-runners/
│   ├── metadata.txt
│   ├── converted_content.html
│   ├── shopify_ready_content.html
│   └── images/
└── csfrace-com_choosing-the-right-running-shoes/
    ├── metadata.txt
    ├── converted_content.html
    ├── shopify_ready_content.html
    └── images/
```

## Creating Your Own Batch Files

### From Excel/Google Sheets

1. Create a column with your URLs
2. Add a header row: `url`
3. Export as CSV
4. Upload to CSFrace Scrape

### From a Website Sitemap

```bash
# Extract URLs from sitemap.xml
curl https://csfrace.com/sitemap.xml | \
  grep -oP '(?<=<loc>).*?(?=</loc>)' | \
  grep '/blog/' > batch-urls.txt
```

### From a List of URLs

```bash
# Create a text file
cat > batch-urls.txt << 'EOF'
https://csfrace.com/blog/post-1
https://csfrace.com/blog/post-2
https://csfrace.com/blog/post-3
EOF
```

## Tips for Large Batches

1. **Test with a small batch first** - Process 5-10 URLs to verify everything works
2. **Break large batches into smaller chunks** - Process 50-100 URLs at a time
3. **Monitor progress** - Check the batch status in the web interface or via API
4. **Review failed jobs** - The system will report which URLs failed and why
5. **Use descriptive batch names** - Makes it easier to track multiple batches

## Troubleshooting

### "Too many URLs" error
- Reduce the number of URLs to 100 or less
- Or split into multiple batches

### "Invalid URL format" error
- Ensure all URLs start with `http://` or `https://`
- Remove any blank lines from your file
- Check for special characters in URLs

### "File format not supported" error
- Use `.txt`, `.csv`, or `.json` file extensions
- Ensure CSV has a `url` header
- Ensure JSON is a valid array of strings

### Some URLs fail to process
- Check the batch summary for specific error messages
- Verify URLs are publicly accessible
- Ensure URLs point to actual blog posts, not category pages

## Need Help?

- [Main Documentation](../../README.md)
- [API Documentation](../api/README.md) (if available)
- [GitHub Issues](https://github.com/zachatkinson/csfrace-scrape/issues)

---

**Ready to process your batch?** Upload one of these example files to get started!
