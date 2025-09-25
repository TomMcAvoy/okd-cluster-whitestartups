#!/bin/zsh
# Organize OSX-KVM/backups and resources folders
KVM_BACKUPS="/Users/thomasmcavoy/GitHub/okd-home-project/GitHub_symlink/OSX-KVM/backups"
KVM_RESOURCES="/Users/thomasmcavoy/GitHub/okd-home-project/GitHub_symlink/OSX-KVM/resources"

# Organize backups: firmware and scripts
mkdir -p "$KVM_BACKUPS/firmware" "$KVM_BACKUPS/scripts"
for file in "$KVM_BACKUPS"/*; do
  [[ -f "$file" ]] || continue
  case "$file" in
    *.fd|*.img|*.dmg|*.old)
      mv "$file" "$KVM_BACKUPS/firmware/"
      ;;
    *.py|*.sh)
      mv "$file" "$KVM_BACKUPS/scripts/"
      ;;
  esac
done

# Organize resources: images, configs, docs
mkdir -p "$KVM_RESOURCES/images" "$KVM_RESOURCES/configs" "$KVM_RESOURCES/docs"
for file in "$KVM_RESOURCES"/*; do
  [[ -f "$file" ]] || continue
  case "$file" in
    *.png|*.jpg|*.jpeg|*.bmp|*.tiff|*.svg)
      mv "$file" "$KVM_RESOURCES/images/"
      ;;
    *.conf|*.xml|*.rules)
      mv "$file" "$KVM_RESOURCES/configs/"
      ;;
    *.md|*.txt)
      mv "$file" "$KVM_RESOURCES/docs/"
      ;;
  esac
done

echo "OSX-KVM backups and resources folders organized."
