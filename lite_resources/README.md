# Lite Resources Directory

This directory contains **2,848 files** extracted from the GameHub-Lite.apk reference APK.

## Contents

These files are required to create the Lite version of GameHub and include:

### 1. **WebP Images** (~2,800+ files)
- Pre-converted WebP images that replace PNG files from the original APK
- Includes all drawable resources (icons, UI elements, etc.)
- Located in `res/drawable*/` and `res/mipmap*/` directories

### 2. **Smali Classes**
- `smali_classes10/` - Contains MTDataFilesProvider classes
- `smali_classes4/` - Additional privacy-focused classes
- `smali_classes5/` - Modified launcher classes

### 3. **Resource Files**
- XML layouts
- Configuration files
- Other resources not present in the original APK

## Size
- **Total size:** ~18MB compressed
- **Total files:** 2,848 files

## Usage

The autopatcher script automatically copies these files during the patching process:

```bash
./autopatcher.sh GameHub_ORG.apk
```

The script copies all files from this directory into the decompiled APK structure before rebuilding.

## Source

These files were extracted from:
- **GameHub-Lite.apk** (50MB reference version)
- Analyzed using `analyze_complete_diff.sh`
- Files that exist in Lite but not in Original

## Do Not Modify

These files are pre-optimized and tested. Modifying them may cause:
- Build failures
- App crashes
- Resource loading errors
