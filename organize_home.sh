#!/bin/bash
# Organize home directory by cleaning up common clutter areas
HOME_DIR="$HOME"

echo "🏠 Organizing Home Directory: $HOME_DIR"
echo "=========================================="

# Create organized directories
mkdir -p "$HOME_DIR/Desktop/Screenshots"
mkdir -p "$HOME_DIR/Desktop/Temporary Files"
mkdir -p "$HOME_DIR/Desktop/Quick Access"
mkdir -p "$HOME_DIR/Archive/Old Desktop Items"
mkdir -p "$HOME_DIR/Archive/Old Downloads"

# Function to move files with logging
move_with_log() {
    local source="$1"
    local destination="$2"
    local description="$3"
    
    count=0
    if [[ -d "$source" ]]; then
        for item in "$source"/*; do
            if [[ -e "$item" ]]; then
                mv "$item" "$destination/"
                ((count++))
            fi
        done
    fi
    
    if [[ $count -gt 0 ]]; then
        echo "✅ Moved $count $description"
    fi
}

# Clean up Desktop
echo ""
echo "🖥️  Cleaning Desktop..."
echo "----------------------"

# Move screenshots to organized folder
move_with_log "$HOME_DIR/Desktop" "$HOME_DIR/Desktop/Screenshots" "screenshot files"
find "$HOME_DIR/Desktop" -name "Screen Shot*" -type f -exec mv {} "$HOME_DIR/Desktop/Screenshots/" \; 2>/dev/null
find "$HOME_DIR/Desktop" -name "Screenshot*" -type f -exec mv {} "$HOME_DIR/Desktop/Screenshots/" \; 2>/dev/null

# Move temporary files
find "$HOME_DIR/Desktop" -name "Untitled*" -type f -exec mv {} "$HOME_DIR/Desktop/Temporary Files/" \; 2>/dev/null
find "$HOME_DIR/Desktop" -name ".*" -type f ! -name ".DS_Store" -exec mv {} "$HOME_DIR/Desktop/Temporary Files/" \; 2>/dev/null

# Archive old downloads on desktop
find "$HOME_DIR/Desktop" -name "*.dmg" -type f -exec mv {} "$HOME_DIR/Archive/Old Desktop Items/" \; 2>/dev/null
find "$HOME_DIR/Desktop" -name "*.pkg" -type f -exec mv {} "$HOME_DIR/Archive/Old Desktop Items/" \; 2>/dev/null

# Clean up root home directory files
echo ""
echo "📂 Cleaning Home Directory Root..."
echo "-----------------------------------"

# Move loose files from home root to appropriate locations
temp_files=0
for file in "$HOME_DIR"/*; do
    if [[ -f "$file" ]]; then
        case "${file##*/}" in
            *.pdf|*.doc|*.docx|*.txt)
                mv "$file" "$HOME_DIR/Documents/"
                ((temp_files++))
                ;;
            *.jpg|*.jpeg|*.png|*.gif|*.heic)
                mkdir -p "$HOME_DIR/Pictures/Unsorted"
                mv "$file" "$HOME_DIR/Pictures/Unsorted/"
                ((temp_files++))
                ;;
            *.zip|*.dmg|*.pkg)
                mv "$file" "$HOME_DIR/Archive/Old Downloads/"
                ((temp_files++))
                ;;
            *.mp3|*.m4a|*.wav)
                mkdir -p "$HOME_DIR/Music/Unsorted"
                mv "$file" "$HOME_DIR/Music/Unsorted/"
                ((temp_files++))
                ;;
        esac
    fi
done

if [[ $temp_files -gt 0 ]]; then
    echo "✅ Organized $temp_files loose files from home directory"
fi

# Clean up common cache directories
echo ""
echo "🧹 Cleaning Cache and Temporary Files..."
echo "----------------------------------------"

# Clean Trash (if possible)
if command -v trash &> /dev/null; then
    trash -e 2>/dev/null && echo "✅ Emptied Trash"
fi

# Clear some common cache locations (safely)
cache_cleaned=0
if [[ -d "$HOME_DIR/Library/Caches" ]]; then
    find "$HOME_DIR/Library/Caches" -name "*.cache" -type f -mtime +7 -delete 2>/dev/null
    ((cache_cleaned++))
fi

if [[ cache_cleaned -gt 0 ]]; then
    echo "✅ Cleaned old cache files"
fi

# Organize Applications folder if user has one in home
if [[ -d "$HOME_DIR/Applications" ]]; then
    echo ""
    echo "📱 Found personal Applications folder"
    app_count=$(find "$HOME_DIR/Applications" -name "*.app" | wc -l)
    echo "   Contains $app_count applications"
fi

# Summary
echo ""
echo "🎉 Home Directory Organization Complete!"
echo "========================================"
echo "Created organized structure:"
echo "  📁 Desktop/Screenshots - for screenshot files"
echo "  📁 Desktop/Temporary Files - for temporary items"  
echo "  📁 Desktop/Quick Access - for frequently used items"
echo "  📁 Archive/Old Desktop Items - for old installers/packages"
echo "  📁 Archive/Old Downloads - for old downloaded files"
echo ""
echo "💡 Tips for staying organized:"
echo "  • Use Desktop/Quick Access for current projects"
echo "  • Regularly clean Desktop/Temporary Files"
echo "  • Archive old files instead of deleting them"
echo "  • Use descriptive folder names"