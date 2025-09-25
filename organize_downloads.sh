#!/bin/zsh
# Organize Downloads directory by file type
DOWNLOADS="$HOME/Downloads"

# Define categories and extensions
categories=(
  Documents:pdf,doc,docx,xls,xlsx,ppt,pptx,txt,md
  Images:jpg,jpeg,png,gif,bmp,tiff,svg,heic
  Archives:zip,tar,gz,rar,7z,tgz
  Installers:dmg,pkg,app,exe,msi,deb,rpm
  Audio:mp3,wav,aac,flac,ogg,m4a
  Video:mp4,mov,avi,mkv,wmv,flv,webm
  Scripts:sh,py,js,ts,rb,pl,go
)


for category in $categories; do
  name=${category%%:*}
  exts=${category#*:}
  folder="$DOWNLOADS/$name"
  mkdir -p "$folder"
  for ext in ${(s:,:)exts}; do
    find "$DOWNLOADS" -maxdepth 1 -type f -iname "*.$ext" -exec mv {} "$folder" \;
  done

done

# Move uncategorized files to "Others" using a zsh loop
known_exts=(pdf doc docx xls xlsx ppt pptx txt md jpg jpeg png gif bmp tiff svg heic zip tar gz rar 7z tgz dmg pkg app exe msi deb rpm mp3 wav aac flac ogg m4a mp4 mov avi mkv wmv flv webm sh py js ts rb pl go)
mkdir -p "$DOWNLOADS/Others"
for file in "$DOWNLOADS"/*; do
  [[ -f "$file" ]] || continue
  ext="${file##*.}"
  found=0
  for kext in $known_exts; do
    if [[ "${ext:l}" == "$kext" ]]; then
      found=1
      break
    fi
  done
  if [[ $found -eq 0 ]]; then
    mv "$file" "$DOWNLOADS/Others/"
  fi
done

# Move uncategorized files to "Others"


known_exts=(pdf doc docx xls xlsx ppt pptx txt md jpg jpeg png gif bmp tiff svg heic zip tar gz rar 7z tgz dmg pkg app exe msi deb rpm mp3 wav aac flac ogg m4a mp4 mov avi mkv wmv flv webm sh py js ts rb pl go)
mkdir -p "$DOWNLOADS/Others"
find_cmd=(find "$DOWNLOADS" -maxdepth 1 -type f)
for ext in $known_exts; do
  find_cmd+=(-not -iname "*.$ext")
done
find_cmd+=(-exec mv {} "$DOWNLOADS/Others" \;)
eval "$find_cmd"

echo "Downloads directory organized by file type."
