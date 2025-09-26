#!/bin/bash
# Organize Downloads directory by file type
DOWNLOADS="$HOME/Downloads"

echo "Organizing Downloads directory: $DOWNLOADS"

# Define categories and extensions
categories=(
  "Documents:pdf,doc,docx,xls,xlsx,ppt,pptx,txt,md"
  "Images:jpg,jpeg,png,gif,bmp,tiff,svg,heic"
  "Archives:zip,tar,gz,rar,7z,tgz"
  "Installers:dmg,pkg,app,exe,msi,deb,rpm"
  "Audio:mp3,wav,aac,flac,ogg,m4a"
  "Video:mp4,mov,avi,mkv,wmv,flv,webm"
  "Scripts:sh,py,js,ts,rb,pl,go"
)

# Create directories and move files
for category_line in "${categories[@]}"; do
  category="${category_line%%:*}"
  exts="${category_line#*:}"
  folder="$DOWNLOADS/$category"
  mkdir -p "$folder"
  echo "Processing $category files..."
  
  # Split extensions by comma and process each
  IFS=',' read -ra ext_array <<< "$exts"
  for ext in "${ext_array[@]}"; do
    # Find and move files with this extension (both lowercase and uppercase)
    find "$DOWNLOADS" -maxdepth 1 -type f \( -iname "*.$ext" \) -exec mv {} "$folder/" \; 2>/dev/null
  done
done

# Move uncategorized files to "Others"
known_exts=(pdf doc docx xls xlsx ppt pptx txt md jpg jpeg png gif bmp tiff svg heic zip tar gz rar 7z tgz dmg pkg app exe msi deb rpm mp3 wav aac flac ogg m4a mp4 mov avi mkv wmv flv webm sh py js ts rb pl go)
mkdir -p "$DOWNLOADS/Others"

echo "Moving uncategorized files to Others..."
for file in "$DOWNLOADS"/*; do
  [[ -f "$file" ]] || continue
  filename=$(basename "$file")
  ext="${filename##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
  found=0
  
  for kext in "${known_exts[@]}"; do
    if [[ "$ext" == "$kext" ]]; then
      found=1
      break
    fi
  done
  
  if [[ $found -eq 0 ]]; then
    mv "$file" "$DOWNLOADS/Others/"
    echo "Moved $filename to Others"
  fi
done

echo "Downloads directory organized by file type."
