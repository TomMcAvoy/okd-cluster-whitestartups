ons #!/bin/bash
# Organize Documents directory by file type and date
DOCUMENTS="$HOME/Documents"

echo "Organizing Documents directory: $DOCUMENTS"

# Create organized directory structure
mkdir -p "$DOCUMENTS/PDF Documents"
mkdir -p "$DOCUMENTS/Word Documents"
mkdir -p "$DOCUMENTS/Excel Spreadsheets"
mkdir -p "$DOCUMENTS/PowerPoint Presentations"
mkdir -p "$DOCUMENTS/Text Files"
mkdir -p "$DOCUMENTS/Images"
mkdir -p "$DOCUMENTS/Archives"
mkdir -p "$DOCUMENTS/Code Projects"
mkdir -p "$DOCUMENTS/Miscellaneous"

# Function to move files safely
move_files() {
    local pattern="$1"
    local destination="$2"
    local description="$3"
    
    count=0
    for file in "$DOCUMENTS"/$pattern; do
        if [[ -f "$file" ]]; then
            mv "$file" "$destination/"
            ((count++))
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        echo "Moved $count $description files"
    fi
}

# Organize PDF files
move_files "*.pdf" "$DOCUMENTS/PDF Documents" "PDF"
move_files "*.PDF" "$DOCUMENTS/PDF Documents" "PDF"

# Organize Word documents
move_files "*.doc" "$DOCUMENTS/Word Documents" "Word"
move_files "*.docx" "$DOCUMENTS/Word Documents" "Word"
move_files "*.DOC" "$DOCUMENTS/Word Documents" "Word"
move_files "*.DOCX" "$DOCUMENTS/Word Documents" "Word"

# Organize Excel files
move_files "*.xls" "$DOCUMENTS/Excel Spreadsheets" "Excel"
move_files "*.xlsx" "$DOCUMENTS/Excel Spreadsheets" "Excel"
move_files "*.XLS" "$DOCUMENTS/Excel Spreadsheets" "Excel"
move_files "*.XLSX" "$DOCUMENTS/Excel Spreadsheets" "Excel"
move_files "*.csv" "$DOCUMENTS/Excel Spreadsheets" "CSV"

# Organize PowerPoint files
move_files "*.ppt" "$DOCUMENTS/PowerPoint Presentations" "PowerPoint"
move_files "*.pptx" "$DOCUMENTS/PowerPoint Presentations" "PowerPoint"
move_files "*.PPT" "$DOCUMENTS/PowerPoint Presentations" "PowerPoint"
move_files "*.PPTX" "$DOCUMENTS/PowerPoint Presentations" "PowerPoint"

# Organize text files
move_files "*.txt" "$DOCUMENTS/Text Files" "text"
move_files "*.rtf" "$DOCUMENTS/Text Files" "RTF"
move_files "*.md" "$DOCUMENTS/Text Files" "Markdown"
move_files "*.TXT" "$DOCUMENTS/Text Files" "text"

# Organize image files
move_files "*.jpg" "$DOCUMENTS/Images" "image"
move_files "*.jpeg" "$DOCUMENTS/Images" "image"
move_files "*.png" "$DOCUMENTS/Images" "image"
move_files "*.gif" "$DOCUMENTS/Images" "image"
move_files "*.bmp" "$DOCUMENTS/Images" "image"
move_files "*.tiff" "$DOCUMENTS/Images" "image"
move_files "*.svg" "$DOCUMENTS/Images" "image"
move_files "*.heic" "$DOCUMENTS/Images" "image"

# Organize archive files
move_files "*.zip" "$DOCUMENTS/Archives" "archive"
move_files "*.tar" "$DOCUMENTS/Archives" "archive"
move_files "*.gz" "$DOCUMENTS/Archives" "archive"
move_files "*.rar" "$DOCUMENTS/Archives" "archive"
move_files "*.7z" "$DOCUMENTS/Archives" "archive"

# Organize code files
move_files "*.js" "$DOCUMENTS/Code Projects" "JavaScript"
move_files "*.py" "$DOCUMENTS/Code Projects" "Python"
move_files "*.java" "$DOCUMENTS/Code Projects" "Java"
move_files "*.cpp" "$DOCUMENTS/Code Projects" "C++"
move_files "*.c" "$DOCUMENTS/Code Projects" "C"
move_files "*.sh" "$DOCUMENTS/Code Projects" "shell script"
move_files "*.html" "$DOCUMENTS/Code Projects" "HTML"
move_files "*.css" "$DOCUMENTS/Code Projects" "CSS"
move_files "*.ts" "$DOCUMENTS/Code Projects" "TypeScript"

# Move any remaining files to Miscellaneous
remaining_files=0
for file in "$DOCUMENTS"/*; do
    if [[ -f "$file" ]] && [[ ! "$file" == *"/organize_documents.sh" ]]; then
        mv "$file" "$DOCUMENTS/Miscellaneous/"
        ((remaining_files++))
    fi
done

if [[ $remaining_files -gt 0 ]]; then
    echo "Moved $remaining_files miscellaneous files"
fi

# Remove empty directories (but keep the organized ones we created)
find "$DOCUMENTS" -type d -empty ! -path "$DOCUMENTS/PDF Documents*" ! -path "$DOCUMENTS/Word Documents*" ! -path "$DOCUMENTS/Excel Spreadsheets*" ! -path "$DOCUMENTS/PowerPoint Presentations*" ! -path "$DOCUMENTS/Text Files*" ! -path "$DOCUMENTS/Images*" ! -path "$DOCUMENTS/Archives*" ! -path "$DOCUMENTS/Code Projects*" ! -path "$DOCUMENTS/Miscellaneous*" -delete 2>/dev/null

echo ""
echo "📁 Documents organization complete!"
echo "Created organized folders:"
echo "  - PDF Documents"
echo "  - Word Documents" 
echo "  - Excel Spreadsheets"
echo "  - PowerPoint Presentations"
echo "  - Text Files"
echo "  - Images"
echo "  - Archives"
echo "  - Code Projects"
echo "  - Miscellaneous"t7500