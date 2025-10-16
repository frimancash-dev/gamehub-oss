#!/bin/bash

################################################################################
# GameHub Lite Auto-Patcher
#
# This script automatically patches a new GameHub APK to create GameHub Lite
# Compatible with: macOS, Linux
#
# Usage: ./autopatcher.sh <path-to-new-gamehub.apk>
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"
KEYSTORE="$SCRIPT_DIR/gamehub-release.keystore"
KEYSTORE_PASS="password123"
KEY_ALIAS="key0"

# Tool paths (auto-detect)
APKTOOL="apktool"
JAVA_HOME_DETECTED=""
APKSIGNER=""
ZIPALIGN=""

################################################################################
# Functions
################################################################################

print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}    GameHub Lite Auto-Patcher${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}➜${NC} $1"
}

print_error() {
    echo -e "${RED}✗ ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

check_dependencies() {
    print_step "Checking dependencies..."

    # Check for apktool
    if ! command -v apktool &> /dev/null; then
        print_error "apktool not found. Please install apktool first."
        echo "  macOS: brew install apktool"
        echo "  Linux: sudo apt-get install apktool"
        exit 1
    fi
    print_success "apktool found: $(apktool --version | head -1)"

    # Check for Java
    if command -v java &> /dev/null; then
        print_success "Java found: $(java -version 2>&1 | head -1)"
    else
        print_error "Java not found. Please install Java JDK."
        exit 1
    fi

    # Detect Android SDK tools
    if [[ -d "/opt/homebrew/share/android-commandlinetools" ]]; then
        JAVA_HOME_DETECTED="/opt/homebrew/opt/openjdk@17"
        ZIPALIGN="/opt/homebrew/share/android-commandlinetools/build-tools/36.0.0/zipalign"
        APKSIGNER="/opt/homebrew/share/android-commandlinetools/build-tools/36.0.0/apksigner"
    elif [[ -n "$ANDROID_HOME" ]]; then
        # Try to find in ANDROID_HOME
        BUILD_TOOLS_DIR="$ANDROID_HOME/build-tools"
        if [[ -d "$BUILD_TOOLS_DIR" ]]; then
            LATEST_BUILD_TOOLS=$(ls -1 "$BUILD_TOOLS_DIR" | sort -V | tail -1)
            ZIPALIGN="$BUILD_TOOLS_DIR/$LATEST_BUILD_TOOLS/zipalign"
            APKSIGNER="$BUILD_TOOLS_DIR/$LATEST_BUILD_TOOLS/apksigner"
        fi
    fi

    if [[ -z "$ZIPALIGN" ]] || [[ ! -f "$ZIPALIGN" ]]; then
        print_error "zipalign not found. Please install Android SDK build-tools."
        exit 1
    fi
    print_success "zipalign found: $ZIPALIGN"

    if [[ -z "$APKSIGNER" ]] || [[ ! -f "$APKSIGNER" ]]; then
        print_error "apksigner not found. Please install Android SDK build-tools."
        exit 1
    fi
    print_success "apksigner found: $APKSIGNER"

    # Check for keystore
    if [[ ! -f "$KEYSTORE" ]]; then
        print_warning "Keystore not found at: $KEYSTORE"
        echo "Creating new keystore..."
        keytool -genkey -v -keystore "$KEYSTORE" \
            -alias "$KEY_ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
            -storepass "$KEYSTORE_PASS" -keypass "$KEYSTORE_PASS" \
            -dname "CN=GameHub Lite, OU=Dev, O=GameHub, L=Unknown, ST=Unknown, C=US"
        print_success "Keystore created"
    fi

    echo ""
}

create_patches_dir() {
    print_step "Checking patches directory..."

    if [[ ! -d "$PATCHES_DIR" ]]; then
        print_error "Patches directory not found: $PATCHES_DIR"
        echo "Creating patches from DIFF_comparison..."

        mkdir -p "$PATCHES_DIR"

        # Copy diff files as patches
        if [[ -d "$SCRIPT_DIR/DIFF_comparison" ]]; then
            cp "$SCRIPT_DIR/DIFF_comparison"/*.diff "$PATCHES_DIR/" 2>/dev/null || true
            print_success "Patches directory created with $(ls -1 "$PATCHES_DIR"/*.diff 2>/dev/null | wc -l) patches"
        else
            print_error "DIFF_comparison directory not found. Please run the diff comparison first."
            exit 1
        fi
    else
        PATCH_COUNT=$(ls -1 "$PATCHES_DIR"/*.diff 2>/dev/null | wc -l)
        print_success "Found $PATCH_COUNT patches"
    fi
    echo ""
}

decompile_apk() {
    local apk_path="$1"
    local output_dir="$2"

    print_step "Decompiling APK: $(basename "$apk_path")"

    if [[ -d "$output_dir" ]]; then
        print_warning "Output directory exists, removing: $output_dir"
        rm -rf "$output_dir"
    fi

    apktool d "$apk_path" -o "$output_dir" -f
    print_success "APK decompiled to: $output_dir"
    echo ""
}

apply_patches() {
    local target_dir="$1"

    print_step "Applying patches..."

    local success_count=0
    local fail_count=0
    local skip_count=0

    # Apply critical patches first
    local critical_patches=(
        "AndroidManifest.xml.diff"
    )

    for patch_file in "${critical_patches[@]}"; do
        local full_patch="$PATCHES_DIR/$patch_file"
        if [[ -f "$full_patch" ]]; then
            echo "  Applying CRITICAL: $patch_file"

            # Extract the target file from patch (strip directory and timestamp)
            local target_file=$(head -1 "$full_patch" | sed 's|^--- [^/]*/||' | awk '{print $1}')
            local target_path="$target_dir/$target_file"

            if [[ -f "$target_path" ]]; then
                if patch -p1 -d "$target_dir" < "$full_patch" --dry-run &>/dev/null; then
                    patch -p1 -d "$target_dir" < "$full_patch" &>/dev/null
                    success_count=$((success_count + 1))
                    echo -e "    ${GREEN}✓ Applied${NC}"
                else
                    print_warning "Patch failed (file may have changed in new version): $patch_file"
                    fail_count=$((fail_count + 1))
                fi
            else
                print_warning "Target file not found: $target_file"
                skip_count=$((skip_count + 1))
            fi
        fi
    done

    # Apply remaining patches
    for patch_file in "$PATCHES_DIR"/*.diff; do
        local patch_name=$(basename "$patch_file")

        # Skip if already applied (critical patches)
        [[ " ${critical_patches[@]} " =~ " ${patch_name} " ]] && continue

        echo "  Applying: $patch_name"

        # Extract the target file from patch (strip directory and timestamp)
        local target_file=$(head -1 "$patch_file" | sed 's|^--- [^/]*/||' | awk '{print $1}')
        local target_path="$target_dir/$target_file"

        if [[ -f "$target_path" ]]; then
            if patch -p1 -d "$target_dir" < "$patch_file" --dry-run &>/dev/null; then
                patch -p1 -d "$target_dir" < "$patch_file" &>/dev/null
                success_count=$((success_count + 1))
                echo -e "    ${GREEN}✓ Applied${NC}"
            else
                print_warning "Patch failed (file may have changed): $patch_name"
                fail_count=$((fail_count + 1))
            fi
        else
            skip_count=$((skip_count + 1))
        fi
    done

    echo ""
    print_success "Patches applied: $success_count"
    [[ $fail_count -gt 0 ]] && print_warning "Patches failed: $fail_count"
    [[ $skip_count -gt 0 ]] && print_warning "Patches skipped (file not found): $skip_count"
    echo ""
}

remove_bloat_files() {
    local target_dir="$1"

    print_step "Removing telemetry, analytics, and bloat files (complete removal list)..."

    local removed_count=0
    local removal_list="$SCRIPT_DIR/files_to_remove.txt"

    if [[ -f "$removal_list" ]]; then
        while IFS= read -r file_path || [[ -n "$file_path" ]]; do
            # Skip empty lines
            [[ -z "$file_path" ]] && continue

            local full_path="$target_dir/$file_path"

            # Remove file or directory
            if [[ -e "$full_path" ]]; then
                rm -rf "$full_path"
                removed_count=$((removed_count + 1))

                # Progress indicator
                if [ $((removed_count % 1000)) -eq 0 ]; then
                    echo "  ... removed $removed_count items"
                fi
            fi
        done < "$removal_list"

        print_success "Removed $removed_count files and directories (from complete analysis)"
    else
        print_warning "Complete removal list not found: $removal_list"
        print_warning "Falling back to basic conversion_rules.txt"

        # Fallback to old method
        local rules_file="$SCRIPT_DIR/conversion_rules.txt"
        if [[ -f "$rules_file" ]]; then
            while IFS= read -r line || [[ -n "$line" ]]; do
                [[ "$line" =~ ^#.*$ ]] && continue
                [[ -z "$line" ]] && continue
                rm -rf "$target_dir/$line" 2>/dev/null || true
            done < "$rules_file"
            print_success "Removed basic telemetry files"
        fi
    fi

    echo ""
}

copy_additional_files() {
    local target_dir="$1"

    print_step "Copying additional files from Lite resources (WebP images, etc.)..."

    local files_source="$SCRIPT_DIR/lite_resources"
    local copied_count=0

    if [[ -d "$files_source" ]]; then
        # Copy all files from lite_resources, excluding META-INF
        while IFS= read -r source_file; do
            # Get relative path
            local rel_path="${source_file#$files_source/}"

            # Skip META-INF (will be regenerated on signing)
            [[ "$rel_path" =~ ^META-INF/ ]] && continue

            # Create target directory
            local target_file="$target_dir/$rel_path"
            mkdir -p "$(dirname "$target_file")"

            # Copy file
            cp "$source_file" "$target_file"
            copied_count=$((copied_count + 1))

            # Progress indicator
            if [ $((copied_count % 500)) -eq 0 ]; then
                echo "  ... copied $copied_count files"
            fi
        done < <(find "$files_source" -type f)

        print_success "Copied $copied_count additional files (WebP images, smali classes)"
    else
        print_warning "Lite resources directory not found: $files_source"
        print_warning "Run ./analyze_complete_diff.sh first to extract Lite resources"
        exit 1
    fi

    echo ""
}

copy_additional_classes() {
    local target_dir="$1"

    print_step "Checking additional smali classes..."

    # Check if smali_classes10 already exists (from files_to_add)
    if [[ -d "$target_dir/smali_classes10" ]]; then
        print_success "smali_classes10 already exists (MTDataFilesProvider included from analysis)"
    else
        # Fallback: Copy smali_classes10 (MTDataFilesProvider classes)
        local smali10_source="$SCRIPT_DIR/smali_classes10_new"
        if [[ -d "$smali10_source" ]]; then
            cp -r "$smali10_source" "$target_dir/smali_classes10"
            print_success "Copied smali_classes10 directory (MTDataFilesProvider classes)"
        else
            print_warning "smali_classes10 not found - MTDataFilesProvider may be missing"
        fi
    fi

    echo ""
}

apply_manual_modifications() {
    local target_dir="$1"

    print_step "Applying manual modifications..."

    # 1. Package name change (if not already in patch)
    local manifest="$target_dir/AndroidManifest.xml"
    if grep -q 'package="gamehub.org"' "$manifest" 2>/dev/null; then
        sed -i.bak 's/package="gamehub.org"/package="gamehub.lite"/g' "$manifest"
        sed -i.bak 's/gamehub.org/gamehub.lite/g' "$manifest"
        print_success "Package name changed to gamehub.lite"
    fi

    # 2. Add MTDataFilesProvider if missing (required for app to work)
    if ! grep -q 'MTDataFilesProvider' "$manifest"; then
        print_step "Adding MTDataFilesProvider to manifest..."
        # Find the closing </application> tag and insert before it
        sed -i.bak '/<\/application>/i\
        <activity android:label="@string/adb_pairing" android:name="com.xiaoji.wifi.adb.AdbPairingTutorialActivity"/>\
        <activity android:excludeFromRecents="true" android:exported="true" android:name="bin.mt.file.content.MTDataFilesWakeUpActivity" android:noHistory="true" android:taskAffinity="com.xiaoji.egggame.MTDataFilesWakeUp"/>\
        <provider android:authorities="gamehub.lite.MTDataFilesProvider" android:exported="true" android:grantUriPermissions="true" android:name="bin.mt.file.content.MTDataFilesProvider" android:permission="android.permission.MANAGE_DOCUMENTS">\
            <intent-filter>\
                <action android:name="android.content.action.DOCUMENTS_PROVIDER"/>\
            </intent-filter>\
        </provider>
' "$manifest"
        print_success "Added MTDataFilesProvider to manifest"
    else
        print_success "MTDataFilesProvider already in manifest"
    fi

    # 2b. Remove Firebase/Google services providers (causes crash since we removed their classes)
    if grep -q 'FirebaseInitProvider' "$manifest"; then
        print_step "Removing Firebase/Google services providers..."
        # Remove FirebaseInitProvider
        sed -i.bak '/<provider.*FirebaseInitProvider/,/<\/provider>/d' "$manifest"
        # Remove Firebase ComponentDiscoveryService
        sed -i.bak '/<service.*ComponentDiscoveryService/,/<\/service>/d' "$manifest"
        print_success "Removed Firebase providers"
    fi

    # 3. Smali fix for NumberFormatException (emulation frontend support)
    local gamedetail_smali="$target_dir/smali_classes5/com/xj/landscape/launcher/ui/gamedetail/GameDetailActivity.smali"
    if [[ -f "$gamedetail_smali" ]]; then
        if grep -q 'const-string v8, ""' "$gamedetail_smali"; then
            # Find and replace the specific line for "type" parameter
            sed -i.bak '/const-string v7, "type"/,/const-string v8/ s/const-string v8, ""/const-string v8, "0"/' "$gamedetail_smali"
            print_success "Fixed NumberFormatException in GameDetailActivity"
        fi
    fi

    # 4. Make GameDetailActivity exportable for emulation frontend
    if grep -q 'android:name="com.xj.landscape.launcher.ui.gamedetail.GameDetailActivity"' "$manifest"; then
        # Check if not already exported
        if ! grep -A 3 'android:name="com.xj.landscape.launcher.ui.gamedetail.GameDetailActivity"' "$manifest" | grep -q 'android:exported="true"'; then
            # This is complex, better to ensure it's in the patch file
            print_warning "GameDetailActivity export should be in patch file"
        fi
    fi

    # 5. Fix public.xml - remove invalid entries where resource name contains file extension
    local public_xml="$target_dir/res/values/public.xml"
    if [[ -f "$public_xml" ]]; then
        # Remove lines where the name ends with file extensions (these are invalid duplicates)
        sed -i.bak -e '/\.png"/d' -e '/\.jpg"/d' -e '/\.jpeg"/d' -e '/\.webp"/d' "$public_xml"
        rm -f "$public_xml.bak"
        print_success "Fixed public.xml (removed invalid resource names with file extensions)"
    fi

    # 5. Remove all .bak files created by sed
    find "$target_dir" -name "*.bak" -delete 2>/dev/null || true

    # 6. Copy custom resources if they exist
    if [[ -f "$SCRIPT_DIR/wine_logo.png" ]]; then
        # Convert to webp and copy
        if command -v cwebp &> /dev/null; then
            cwebp -q 100 "$SCRIPT_DIR/wine_logo.png" -o "$target_dir/res/drawable-xxhdpi/wine_logo.webp" 2>/dev/null
            print_success "Custom wine logo added"
        fi
    fi

    echo ""
}

rebuild_apk() {
    local source_dir="$1"
    local output_apk="$2"

    print_step "Rebuilding APK..."

    apktool b "$source_dir" -o "$output_apk"
    print_success "APK built: $output_apk"
    echo ""
}

sign_apk() {
    local input_apk="$1"
    local output_apk="$2"

    print_step "Aligning and signing APK..."

    # Align
    local aligned_apk="${input_apk%.apk}-aligned.apk"
    "$ZIPALIGN" -v 4 "$input_apk" "$aligned_apk"
    print_success "APK aligned"

    # Sign
    if [[ -n "$JAVA_HOME_DETECTED" ]]; then
        export JAVA_HOME="$JAVA_HOME_DETECTED"
    fi

    "$APKSIGNER" sign \
        --ks "$KEYSTORE" \
        --ks-pass pass:"$KEYSTORE_PASS" \
        --key-pass pass:"$KEYSTORE_PASS" \
        --v1-signing-enabled true \
        --v2-signing-enabled true \
        --v3-signing-enabled true \
        "$aligned_apk"

    print_success "APK signed"

    # Verify
    "$APKSIGNER" verify --verbose "$aligned_apk" > /dev/null 2>&1
    print_success "APK signature verified"

    # Move to final location
    mv "$aligned_apk" "$output_apk"
    rm -f "$input_apk"

    echo ""
}

################################################################################
# Main Script
################################################################################

main() {
    print_header

    # Check arguments
    if [[ $# -eq 0 ]]; then
        print_error "No APK file specified"
        echo "Usage: $0 <path-to-gamehub.apk>"
        echo ""
        echo "Example: $0 GameHub-5.2.0.apk"
        exit 1
    fi

    local input_apk="$1"

    if [[ ! -f "$input_apk" ]]; then
        print_error "APK file not found: $input_apk"
        exit 1
    fi

    # Get APK info
    local apk_name=$(basename "$input_apk" .apk)
    local version=$(echo "$apk_name" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")

    # If no version detected, use timestamp
    if [[ -z "$version" ]]; then
        version=$(date +"%Y%m%d-%H%M%S")
        print_step "Input APK: $input_apk"
        print_step "No version detected, using timestamp: $version"
    else
        print_step "Input APK: $input_apk"
        print_step "Detected version: $version"
    fi
    echo ""

    # Check dependencies
    check_dependencies

    # Create/check patches directory
    create_patches_dir

    # Define working directories
    local work_dir="$SCRIPT_DIR/work_temp"
    local decompiled_dir="$work_dir/decompiled"
    local output_apk="$SCRIPT_DIR/GameHub-Lite-${version}-patched.apk"
    local final_apk="$SCRIPT_DIR/GameHub-Lite-${version}-signed.apk"

    # Clean work directory
    if [[ -d "$work_dir" ]]; then
        rm -rf "$work_dir"
    fi
    mkdir -p "$work_dir"

    # Step 1: Decompile
    decompile_apk "$input_apk" "$decompiled_dir"

    # Step 2: Remove bloat files (telemetry, analytics, unused libs)
    remove_bloat_files "$decompiled_dir"

    # Step 3: Copy additional files (pre-converted WebP images from Lite APK)
    copy_additional_files "$decompiled_dir"

    # Step 4: Apply patches
    apply_patches "$decompiled_dir"

    # Step 5: Copy additional classes (smali_classes10)
    copy_additional_classes "$decompiled_dir"

    # Step 6: Apply manual modifications
    apply_manual_modifications "$decompiled_dir"

    # Step 7: Rebuild
    rebuild_apk "$decompiled_dir" "$output_apk"

    # Step 8: Sign
    sign_apk "$output_apk" "$final_apk"

    # Cleanup
    print_step "Cleaning up temporary files..."
    rm -rf "$work_dir"
    print_success "Cleanup complete"
    echo ""

    # Final summary
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ PATCHING COMPLETE!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Output APK: $final_apk"
    echo "Size: $(du -h "$final_apk" | cut -f1)"
    echo ""
    echo "You can now install this APK:"
    echo "  adb install -r \"$final_apk\""
    echo ""
}

# Run main function
main "$@"
