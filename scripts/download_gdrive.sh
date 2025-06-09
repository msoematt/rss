#!/bin/bash

# Google Drive Downloader Script
# Usage: ./download_gdrive.sh "GOOGLE_DRIVE_URL" "output_filename"

if [ $# -ne 2 ]; then
    echo "Usage: $0 \"GOOGLE_DRIVE_URL\" \"output_filename\""
    echo "Example: $0 \"https://drive.usercontent.google.com/download?id=...\" \"my_file.xml\""
    exit 1
fi

GDRIVE_URL="$1"
OUTPUT_FILE="$2"

echo "🔗 Downloading from Google Drive..."
echo "📂 URL: $GDRIVE_URL"
echo "💾 Output: $OUTPUT_FILE"

# Check if backend is running
if ! curl -s http://localhost:8000/api/health > /dev/null; then
    echo "❌ Backend server not running. Please start it first:"
    echo "   cd .website && ./run_all.sh"
    exit 1
fi

# Use backend API to download
RESPONSE=$(curl -s -X POST "http://localhost:8000/api/google-drive/download" \
     -H "Content-Type: application/json" \
     -d "{\"url\": \"$GDRIVE_URL\", \"filename\": \"temp_download\"}")

# Check if download was successful
if echo "$RESPONSE" | grep -q '"success":true'; then
    # Extract the local path
    LOCAL_PATH=$(echo "$RESPONSE" | sed -n 's/.*"local_path":"\([^"]*\)".*/\1/p')
    
    if [ -f "$LOCAL_PATH" ]; then
        # Copy to desired output location
        cp "$LOCAL_PATH" "$OUTPUT_FILE"
        FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
        echo "✅ Download successful!"
        echo "📄 File: $OUTPUT_FILE ($FILE_SIZE bytes)"
        
        # Clean up temp file
        rm -f "$LOCAL_PATH"
    else
        echo "❌ Downloaded file not found at: $LOCAL_PATH"
        exit 1
    fi
else
    echo "❌ Download failed:"
    echo "$RESPONSE"
    exit 1
fi 