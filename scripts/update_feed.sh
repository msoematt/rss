#!/bin/bash

# RSS Feed Updater Script
# Usage: ./update_feed.sh "GOOGLE_DRIVE_URL" "feed_name"
# Example: ./update_feed.sh "https://drive.usercontent.google.com/download?id=..." "phil6001"

if [ $# -ne 2 ]; then
    echo "Usage: $0 \"GOOGLE_DRIVE_URL\" \"feed_name\""
    echo "Example: $0 \"https://drive.usercontent.google.com/download?id=...\" \"phil6001\""
    exit 1
fi

GDRIVE_URL="$1"
FEED_NAME="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RSS_DIR="$(dirname "$SCRIPT_DIR")"
FEEDS_DIR="$RSS_DIR/feeds"
FEED_FILE="$FEEDS_DIR/${FEED_NAME}.xml"

echo "🔗 RSS Feed Updater"
echo "📂 URL: $GDRIVE_URL"
echo "📝 Feed: $FEED_NAME"
echo "💾 Output: $FEED_FILE"

# Check if backend is running (in parent directory)
BACKEND_URL="http://localhost:8000"
if ! curl -s "$BACKEND_URL/api/health" > /dev/null; then
    echo "❌ Backend server not running. Please start it first:"
    echo "   cd ../website && ./run_all.sh"
    exit 1
fi

echo "✅ Backend server is running"

# Create feeds directory if it doesn't exist
mkdir -p "$FEEDS_DIR"

# Use backend API to download the RSS feed
echo "📥 Downloading RSS feed..."
RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/google-drive/download" \
    -H "Content-Type: application/json" \
    -d "{\"url\": \"$GDRIVE_URL\", \"filename\": \"temp_feed.xml\"}")

# Parse the response to get the temp file path
TEMP_FILE=$(echo "$RESPONSE" | grep -o '"/var/folders[^"]*"' | tr -d '"')

if [ -z "$TEMP_FILE" ] || [ ! -f "$TEMP_FILE" ]; then
    echo "❌ Download failed. Response: $RESPONSE"
    exit 1
fi

# Copy the downloaded file to the feeds directory
cp "$TEMP_FILE" "$FEED_FILE"

if [ $? -eq 0 ]; then
    echo "✅ RSS feed downloaded successfully: $FEED_FILE"
    
    # Show feed info
    echo ""
    echo "📊 Feed Information:"
    if command -v xmllint > /dev/null; then
        TITLE=$(xmllint --xpath "//channel/title/text()" "$FEED_FILE" 2>/dev/null || echo "Title not found")
        DESCRIPTION=$(xmllint --xpath "//channel/description/text()" "$FEED_FILE" 2>/dev/null || echo "Description not found")
        ITEM_COUNT=$(xmllint --xpath "count(//item)" "$FEED_FILE" 2>/dev/null || echo "Unknown")
        echo "   📚 Title: $TITLE"
        echo "   📝 Description: $DESCRIPTION" 
        echo "   📄 Episodes: $ITEM_COUNT"
    else
        echo "   📄 File size: $(wc -c < "$FEED_FILE") bytes"
    fi
    
    # Clean up temp file
    rm -f "$TEMP_FILE"
    
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Review the feed: cat $FEED_FILE"
    echo "   2. Commit to git: git add feeds/ && git commit -m \"Add $FEED_NAME RSS feed\""
    echo "   3. Push to GitHub: git push origin main"
    echo "   4. RSS URL will be: https://raw.githubusercontent.com/msoematt/rss/main/feeds/${FEED_NAME}.xml"
    
else
    echo "❌ Failed to save RSS feed"
    exit 1
fi 