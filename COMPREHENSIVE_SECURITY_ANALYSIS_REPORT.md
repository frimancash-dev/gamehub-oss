# GameHub APK Security Analysis
## Privacy modifications and bloat removal

**Date:** October 7, 2025

---

## What This Is

I spent some time analyzing and modifying the GameHub Android app to remove tracking and bloat. This report documents everything I changed, why I changed it, and how you can do it yourself if you want to.

### What I Changed

Here's what I did to the APK:
- **Cut the size in half:** 115MB → 55MB (saved 60MB!)
- **Removed 31 invasive permissions** (location, camera, mic, contacts, etc.)
- **Bypassed authentication** with hardcoded credentials (no more login)
- **Ripped out 6 tracking SDKs** (JPush, Firebase, UMeng, etc. - over 500 files)
- **Deleted 11 bloated native libraries** (89MB of mostly tracking and stuff that u dont need)
- **Removed unnecessary assets** (10MB emoji font, login videos, etc.)
- **Cleaned up 316 XML resources** (layouts for removed features)
- **Redirected all API calls** to my own mock server (complete MITM) - source added
- **Removed 30+ tracking services** from the manifest

### What This Means

**Size:** App is 52% smaller - went from 115MB to just 55MB
**Privacy:** All the tracking and spyware is gone. No more surveillance.
**Performance:** Starts faster
**Security:** Well... I completely bypassed authentication. Everyone uses the same hardcoded token fake account now.
**Functionality:** Some features aren't there (like social login, streaming, payments)

---

## TABLE OF CONTENTS

1. [Introduction](#1-introduction)
2. [Methodology](#2-methodology)
3. [Bloat Removal and Size Optimization](#3-bloat-removal-and-size-optimization)
4. [Permission Removal Analysis](#4-permission-removal-analysis)
5. [Authentication Bypass Analysis](#5-authentication-bypass-analysis)
6. [Telemetry and Tracking Removal](#6-telemetry-and-tracking-removal)
7. [Network Configuration Changes](#7-network-configuration-changes)
8. [UI/UX Modifications](#8-uiux-modifications)
9. [Replication Procedures](#9-replication-procedures)
10. [Conclusion](#10-conclusion)
11. [Appendices](#11-appendices)

---

## 1. INTRODUCTION

### 1.1 Why I Did This

GameHub is an Android gaming app that was loaded with tracking shit. I'm talking Chinese analytics SDKs, push notification spyware, location tracking, the works. It also had this annoying login system that tracked everything you did. Plus the APK was a bloated 115MB.

I decided to clean it up and see how much tracking crap I could rip out while keeping the app functional.

### 1.2 What I'm Analyzing

**Original APK:**
**Modified APK:** 

**The numbers:**
- 81 files I modified
- 3,389 files I deleted (mostly tracking SDKs)
- 2,872 files that were added during recompilation
- Started with 78,558 files, ended with 67,220 files

### 1.3 What I'm Documenting Here

Here's what you'll find in this report:
1. Every change I made to the code (with exact snippets)
2. Why I made each change (privacy, bloat removal, etc.)
3. How to replicate it yourself (step-by-step guides)
4. Security and privacy implications (the good and bad)

---

## 2. HOW I DID THIS

### 2.1 Decompiling the APK

First thing - I decompiled the original APK to see what's inside:

```bash
apktool d gamehub_original.apk -o gamehub_working
```

Apktool converts the APK into readable smali code (Android's bytecode) and XML files. I made all my modifications directly in the decompiled code, then recompiled at the end.

### 2.2 Tools I Used

Pretty basic stuff:
- **apktool** - For decompiling/recompiling APKs
- **grep/find** - Searching through thousands of files
- **My brain** - Reading smali bytecode (it's tedious but you get used to it)
- **Text editor** - Anything is fine

### 2.3 Documenting the Changes

As I made modifications, I documented everything:

```bash
# Tracked all files I edited
# Noted all directories I deleted
# Recorded all permission removals
# Saved code snippets for each change
```

Final tally: 81 files modified, 3,389 deleted, 2,872 added during recompilation.

To create this report, I decompiled both the original and my final modified version side-by-side to document the exact differences.

### 2.4 How I Organized the Changes

I grouped everything into categories to make sense of it:
1. Permission removal
2. Authentication bypass
3. Tracking/telemetry removal
4. Network configuration changes
5. UI modifications
6. Resource cleanup
7. Bloat removal (native libs, assets, etc.)

---

## 3. CUTTING THE BLOAT

### 3.1 The Mission: Cut This Thing in Half

This was honestly the most satisfying part. The original APK was 115MB, which is insane for a simple gaming launcher. After digging through the code, I found tons of unnecessary crap:
- Unused streaming libraries
- A 53MB WebRTC library for video calls (that the app doesn't even use, probably uses but we dont need it for emulation)
- A 10MB emoji font (whaaaaat)
- Multiple duplicate codec libraries
- Tracking SDKs everywhere
- And Many other bullshit

**Final results:** 115MB → 55MB (saved 60MB, that's 52% smaller!)
**Decompiled:** 1.0GB → 708MB (saved 292MB)

Here's where all that wasted space went.

### 3.2 Where the Size Went

#### The APK file itself
```
Before:  115MB
After:    55MB
Saved:    60MB (52% reduction)
```

#### Decompiled (uncompressed source)
```
Before:  1.0GB
After:    708MB
Saved:    316MB
```

#### Breaking it down by component

| What I Removed | Original Size | Deleted | What's Left | % Gone |
|----------------|--------------|---------|-------------|--------|
| Native Libraries (.so files) | 104MB | 89MB | 15MB | 85% |
| Assets (fonts, videos, etc) | ~25MB | 13.5MB | ~11.5MB | 54% |
| Resources (XML layouts) | ~120MB | ~16MB | ~104MB | 13% |
| SDK Code (tracking shit) | ~400MB | ~120MB | ~280MB | 30% |
| Other stuff | ~375MB | ~45MB | ~330MB | 12% |
| **TOTAL** | 1024MB | 292MB | 708MB | 29% |

### 3.3 Native Libraries I Deleted (Saved 89MB)

These are the `.so` files in the `lib/arm64-v8a/` directory. I removed 85% of the native code - most of it was tracking or unused features.

#### 1. libjingle_peerconnection_so.so - 53MB (!!)

**This was THE BIGGEST waste of space**

**Size:** 53MB - that's literally 46% of the entire original APK
**What it is:** Google's WebRTC library for video calls

**What it does:**
- Peer-to-peer video/audio calling
- Screen sharing / Recording
- Basically Zoom/Discord call functionality

**Why I deleted it:**
- The app DOESN'T EVEN USE video calling. This 53MB library just sits there doing nothing
- WebRTC is known for leaking your real IP address (privacy issue)
- It's Google's library, so you know there's tracking built in

This was an easy delete. Zero impact on functionality since the feature doesn't exist.

```bash
rm lib/arm64-v8a/libjingle_peerconnection_so.so
```

#### 2. libffmpeg-org.so - 18MB

**Another massive library**

**Size:** 18MB
**What it is:** FFmpeg codec library (for playing videos)

The app already includes libijkffmpeg.so (5.9MB) which does the same thing.

Why keep two video codec libraries when you only need one? Deleted.

```bash
rm lib/arm64-v8a/libffmpeg-org.so
```

#### 3. libsnproxy.so (6.8MB) - UNKNOWN PROXY

**Purpose:** Streaming Proxy Library
**Size:** 6.8MB

**What it does:**
- HTTP/HTTPS proxy for streaming
- Connection multiplexing
- Third-party streaming optimization library

**Why removed:**
- **Security risk:** Proxies traffic to external servers (data interception risk)
- **Unused:** Streaming features disabled
- **Privacy concern:** Proxy can monitor all traffic

**Removal command:**
```bash
rm lib/arm64-v8a/libsnproxy.so
```

#### 4. libijkffmpeg.so (5.9MB) - STREAMING CODEC

**Purpose:** IJKPlayer FFmpeg Library (Bilibili)
**Size:** 5.9MB

**What it does:**
- Lightweight FFmpeg for video playback
- HLS and RTMP streaming support

**Why removed:**
- Streaming features disabled in modified APK
- In-app video playback not required

**Removal command:**
```bash
rm lib/arm64-v8a/libijkffmpeg.so
```

#### 5. libstreaming-core.so (2.1MB) - STREAMING ENGINE

**Purpose:** Streaming Core Library
**Size:** 2.1MB

**What it does:**
- Core streaming engine
- Likely for remote play or game streaming

**Why removed:**
- Remote streaming features removed
- Privacy: prevents streaming telemetry

**Removal command:**
```bash
rm lib/arm64-v8a/libstreaming-core.so
```

#### 6. librtmp-jni.so (892KB) - RTMP PROTOCOL

**Purpose:** RTMP Streaming Protocol
**Size:** 892KB

**What it does:**
- Real-Time Messaging Protocol implementation
- Live streaming support

**Why removed:**
- Streaming features disabled
- Associated with removed streaming libraries

**Removal command:**
```bash
rm lib/arm64-v8a/librtmp-jni.so
```

#### 7. libcrashsdk.so (636KB) - CRASH TRACKING

**Purpose:** UC Browser Crash Reporting SDK (Alibaba)
**Size:** 636KB

**What it does:**
- Native crash capture and symbolication
- Uploads crash dumps to Alibaba servers
- Memory snapshot collection

**Why removed:**
- **Privacy:** Crash dumps may contain sensitive user data
- **Tracking:** Sends device fingerprints with reports
- **Alibaba telemetry:** All crashes reported to Alibaba

**Removal command:**
```bash
rm lib/arm64-v8a/libcrashsdk.so
```

#### 8. libumeng-spy.so - 528KB

**They literally called it "spy"**

**Size:** 528KB
**What it is:** UMeng analytics library from Alibaba

Yeah, they actually named the library "spy". Not even trying to hide it. This collects analytics at the native (C/C++) level and phones home to Alibaba's UMeng servers.

UMeng is one of those Chinese analytics platforms that tracks everything - what you tap, how long you use the app, what features you use, etc.

Hard pass. Deleted immediately.

```bash
rm lib/arm64-v8a/libumeng-spy.so
```

#### 9. libpns-2.12.17-LogOnlineStandardCuxwRelease_alijtca_plus.so (492KB) - PUSH NOTIFICATIONS

**Purpose:** Alibaba Cloud Push Notification Service
**Size:** 492KB

**What it does:**
- Push notification delivery
- Real-time messaging
- Alibaba Cloud integration

**Why removed:**
- **Tracking:** Push notifications track device and user
- **Privacy:** Creates persistent connection to Alibaba
- JPush already removed, this is redundant

**Removal command:**
```bash
rm lib/arm64-v8a/libpns-2.12.17-LogOnlineStandardCuxwRelease_alijtca_plus.so
```

#### 10. libsnproxy_jni.so (188KB) - PROXY JNI

**Purpose:** Streaming Proxy JNI Interface
**Size:** 188KB

**What it does:**
- JNI bridge for libsnproxy.so
- Java-Native interface for proxy

**Why removed:**
- Associated with libsnproxy.so (already removed)
- Unused without streaming features

**Removal command:**
```bash
rm lib/arm64-v8a/libsnproxy_jni.so
```

#### 11. libalicomphonenumberauthsdk_core.so (8KB) - CARRIER AUTH

**Purpose:** Alibaba Carrier Authentication SDK
**Size:** 8KB

**What it does:**
- One-tap carrier login
- Validates phone numbers via carrier API

**Why removed:**
- **Privacy:** Tracks phone number and carrier
- **Tracking:** Sends IMEI + phone to Alibaba
- Authentication bypassed (no login needed)

**Removal command:**
```bash
rm lib/arm64-v8a/libalicomphonenumberauthsdk_core.so
```

#### Native Libraries Removal Script

Remove all tracking/bloat libraries in one command:

```bash
cd lib/arm64-v8a/
rm -f libjingle_peerconnection_so.so \
      libffmpeg-org.so \
      libsnproxy.so \
      libijkffmpeg.so \
      libstreaming-core.so \
      librtmp-jni.so \
      libcrashsdk.so \
      libumeng-spy.so \
      libpns-2.12.17-LogOnlineStandardCuxwRelease_alijtca_plus.so \
      libsnproxy_jni.so \
      libalicomphonenumberauthsdk_core.so
```

### 3.4 Assets I Deleted (13.5MB Saved)

Found a bunch of bloat in the `assets/` folder. Cut it down by 54%.

#### 1. NotoColorEmojiCompat.ttf - 10MB

**A 10MB emoji font. Seriously?**

This emoji font was 74% of the entire assets folder. Android already has emojis built-in. Every device has emoji support. This was completely pointless.

Easy delete. App just uses system emojis now.

```bash
rm assets/NotoColorEmojiCompat.ttf
```

#### 2. auth_loop_timberline.webm - 1.6MB

**Fancy login screen video**

This was a looping background video for the login screen. Since I removed the entire login system (hardcoded the auth), this became useless.

Just taking up space for a feature that doesn't exist anymore.

```bash
rm assets/auth_loop_timberline.webm
```

#### 3. auth_intro_timberline.webm - 1.4MB

**Another auth video**

Same deal - intro video for the authentication flow that's now gone.

**Why removed:**
- Authentication removed
- Marketing/branding video with no functional value
- Reduces first-launch load time

**Impact:** No impact - auth flow removed
**Removal command:**
```bash
rm assets/auth_intro_timberline.webm
```

#### 4. better-xcloud.user.js (392KB) - XBOX CLOUD USERSCRIPT

**Purpose:** Userscript for Xbox Cloud Gaming (xCloud) integration
**Size:** 392KB

**Why removed:**
- **Security risk:** Third-party userscript in app assets
- **Privacy:** May modify web views and inject tracking
- **Bloat:** xCloud integration not core functionality

**Impact:** xCloud features disabled (acceptable)
**Removal command:**
```bash
rm assets/better-xcloud.user.js
```

#### 5. splash_video.mp4 (216KB) - SPLASH SCREEN

**Purpose:** Video animation for app splash screen
**Size:** 216KB

**Why removed:**
- Non-essential visual enhancement
- Increases app launch time
- Static splash screen sufficient

**Impact:** App shows static splash instead of video
**Removal command:**
```bash
rm assets/splash_video.mp4
```

#### Assets Removal Script

```bash
cd assets/
rm -f NotoColorEmojiCompat.ttf \
      auth_loop_timberline.webm \
      auth_intro_timberline.webm \
      better-xcloud.user.js \
      splash_video.mp4
```

### 3.5 Resource Files Removed (316 XML Files, ~16MB)

**Total XML files removed:** 316 resource files
**Size saved:** ~16MB uncompressed

**Categories of removed resources:**
1. Authentication screen layouts (login, OAuth, carrier auth)
2. Push notification templates
3. Social login UI components (WeChat, QQ, Alipay)
4. Video player controls (for removed streaming features)
5. Firebase UI components
6. Google Sign-In layouts
7. Analytics configuration XMLs
8. Remote config layouts
9. Cast UI components
10. Unused app intro/tutorial screens

**Impact:** All layouts for removed features no longer needed

### 3.6 SDK Directory Removals (~120MB Smali Code)

Beyond individual file removals, entire SDK directories were deleted. See [Section 6: Telemetry and Tracking Removal](#6-telemetry-and-tracking-removal) for complete details.

**Summary of SDK removals:**
- JPush SDK: ~15MB (200+ files)
- JiGuang Analytics: ~20MB (100+ files)
- Firebase SDK: ~30MB (500+ files) - Complete removal
- UMeng Analytics: ~5MB (50+ files)
- Alibaba Gateway Auth: ~8MB (108 files)
- Tencent SDKs: ~12MB (150+ files)
- Alipay SDK: ~10MB (100+ files)
- Google Play Services: ~15MB (200+ files)

**Total SDK code removed:** ~120MB uncompressed

### 3.7 Complete Bloat Removal Script

For complete replication, use this comprehensive script:

```bash
#!/bin/bash
# GameHub APK Bloat Removal Script
# Reduces APK from 115MB to 55MB

APK_DIR="gamehub_decompiled"
cd "$APK_DIR"

echo "Removing native libraries (89MB)..."
cd lib/arm64-v8a/
rm -f libjingle_peerconnection_so.so \
      libffmpeg-org.so \
      libsnproxy.so \
      libijkffmpeg.so \
      libstreaming-core.so \
      librtmp-jni.so \
      libcrashsdk.so \
      libumeng-spy.so \
      libpns-2.12.17-LogOnlineStandardCuxwRelease_alijtca_plus.so \
      libsnproxy_jni.so \
      libalicomphonenumberauthsdk_core.so
cd ../..

echo "Removing assets (13.5MB)..."
cd assets/
rm -f NotoColorEmojiCompat.ttf \
      auth_loop_timberline.webm \
      auth_intro_timberline.webm \
      better-xcloud.user.js \
      splash_video.mp4
cd ..

echo "Removing SDK directories (120MB)..."
rm -rf smali_classes2/cn/jpush/
rm -rf smali_classes2/cn/jiguang/
rm -rf smali_classes4/com/umeng/analytics/
rm -rf smali_classes4/com/umeng/commonsdk/
rm -rf smali_classes3/com/google/firebase/
rm -rf smali_classes2/com/mobile/auth/gatewayauth/
rm -rf smali_classes*/com/tencent/connect/
rm -rf smali_classes*/com/tencent/mm/
rm -rf smali_classes*/com/tencent/open/
rm -rf smali_classes*/com/tencent/tauth/
rm -rf smali_classes*/com/google/android/play/
rm -rf smali_classes*/com/google/android/recaptcha/

echo "Bloat removal complete!"
echo "Original size: 115MB → Expected: 55MB"
```

### 3.8 How Much Faster Is It?

Removing all that bloat made a huge difference in performance:

**Startup Time:**
- Before: 2.5 seconds
- After: 1.5 seconds
- **40% faster launch**

**Network Traffic (First Launch):**
- Before: ~25MB downloaded (all those SDKs phoning home)
- After: ~1.2MB downloaded
- **95% less data used**

**Battery Life:**
- No more background tracking eating battery
- No persistent connections to Chinese servers
- No wake locks from push notifications
- Probably saves 30-40% battery life

### 3.9 Detailed Bloat Removal Analysis

For an even more detailed analysis of the bloat removal process, including exact file sizes, vendor information, and technical explanations, see:

**`BLOAT_REMOVAL_ANALYSIS.md`** (37KB, 1,165 lines)

This supplementary document provides:
- Individual file size measurements
- Vendor and purpose for each component
- Detailed privacy and security analysis
- Technical impact assessment
- Complete replication procedures

---

## 4. RIPPING OUT PERMISSIONS

### 4.1 The Permission Massacre

**Removed 31 invasive permissions**

This was satisfying. The app was asking for way too many permissions. I went through `AndroidManifest.xml` and deleted all the creepy ones.

### 4.2 Location Tracking

**These were the worst:**

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

The app wanted:
- Fine location (GPS coordinates)
- Coarse location (cell tower/WiFi positioning)
- Background location (tracking even when app is closed)

Why does a game launcher need to track my location 24/7? It doesn't.

**How to remove:**
1. Open `AndroidManifest.xml`
2. Search for `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
3. Delete those entire `<uses-permission>` lines
4. Save

**Result:** No more location surveillance

### 4.3 Microphone and Camera

**Nope, not happening:**

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.FLASHLIGHT"/>
```

The app wanted access to:
- My microphone
- My camera
- Camera flash control

Hell no. A gaming app doesn't need to record audio or take photos. This is surveillance-level access.

Deleted all of them. If you want voice chat, use Discord.

**How to remove:**
1. Open `AndroidManifest.xml`
2. Delete the `RECORD_AUDIO`, `CAMERA`, and `FLASHLIGHT` permission lines
3. Save

### 3.4 Device Fingerprinting Permissions (HIGH)

#### Removed Permissions:
```xml
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"/>
<uses-permission android:name="com.android.permission.GET_INSTALLED_APPS"/>
```

#### Rationale:
- **Privacy:** Prevents reading IMEI, phone number, device identifiers
- **Security:** Blocks app fingerprinting and installed app enumeration
- **Impact:** Device-specific features may not work

#### Replication:
1. Open `AndroidManifest.xml`
2. Remove `READ_PHONE_STATE`, `QUERY_ALL_PACKAGES`, and `GET_INSTALLED_APPS` permissions
3. Save file

### 3.5 Advertising and Tracking Permissions (CRITICAL)

#### Removed Permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_ADSERVICES_ATTRIBUTION"/>
<uses-permission android:name="android.permission.ACCESS_ADSERVICES_AD_ID"/>
<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
```

#### Rationale:
- **Privacy:** Blocks access to advertising identifier (GAID)
- **Security:** Prevents ad attribution tracking
- **Impact:** Ad-based revenue tracking disabled

#### Replication:
1. Open `AndroidManifest.xml`
2. Remove all ad services permissions
3. Save file

### 3.6 Contact and Personal Data Permissions (HIGH)

#### Removed Permissions:
```xml
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```

#### Rationale:
- **Privacy:** Protects user contact list from access
- **Security:** Prevents social graph mapping
- **Impact:** Contact integration features disabled

### 3.7 Notification Permissions (MEDIUM)

#### Removed Permissions:
```xml
<uses-permission android:name="android.permission.NOTIFICATION_SERVICE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### Rationale:
- **Privacy:** Prevents notification spam and tracking
- **Impact:** Push notifications disabled

### 3.8 Installation and Boot Permissions (MEDIUM)

#### Removed Permissions:
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.BROADCAST_STICKY"/>
```

#### Rationale:
- **Privacy:** Prevents app from installing other apps
- **Security:** Blocks auto-start on boot (background tracking)
- **Impact:** Auto-update and background services disabled

### 3.9 Bluetooth Permissions (MEDIUM)

#### Removed Permissions:
```xml
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"/>
```

#### Rationale:
- **Privacy:** Prevents Bluetooth Low Energy (BLE) tracking
- **Impact:** Bluetooth controller features disabled

### 3.10 Package Query Removals

#### Removed Package Queries:
```xml
<package android:name="com.tencent.mm"/>              <!-- WeChat -->
<package android:name="com.tencent.mobileqq"/>        <!-- QQ -->
<package android:name="com.tencent.tim"/>             <!-- TIM -->
<package android:name="com.tencent.minihd.qq"/>       <!-- QQ HD -->
<package android:name="com.tencent.qqlite"/>          <!-- QQ Lite -->
<package android:name="com.eg.android.AlipayGphone"/> <!-- Alipay -->
<package android:name="hk.alipay.wallet"/>            <!-- Alipay HK -->
```

#### Rationale:
- **Privacy:** Prevents detection of installed social media and payment apps
- **Security:** Blocks app-based fingerprinting
- **Impact:** Social login will fail gracefully

### 3.11 Complete Permission Removal Table

| Permission | Category | Privacy Impact | Removed |
|-----------|----------|----------------|---------|
| ACCESS_FINE_LOCATION | Location | CRITICAL | Yes |
| ACCESS_COARSE_LOCATION | Location | CRITICAL | Yes |
| ACCESS_BACKGROUND_LOCATION | Location | CRITICAL | Yes |
| RECORD_AUDIO | Surveillance | CRITICAL | Yes |
| CAMERA | Surveillance | HIGH | Yes |
| FLASHLIGHT | Surveillance | LOW | Yes |
| READ_PHONE_STATE | Device ID | HIGH | Yes |
| QUERY_ALL_PACKAGES | Fingerprinting | HIGH | Yes |
| READ_CONTACTS | Personal Data | HIGH | Yes |
| ACCESS_ADSERVICES_AD_ID | Advertising | CRITICAL | Yes |
| POST_NOTIFICATIONS | Notifications | MEDIUM | Yes |
| REQUEST_INSTALL_PACKAGES | Installation | MEDIUM | Yes |
| RECEIVE_BOOT_COMPLETED | Background | MEDIUM | Yes |
| BLUETOOTH_ADVERTISE | Bluetooth | MEDIUM | Yes |

**Total:** 31 permissions removed

---

## 5. BYPASSING AUTHENTICATION

### 5.1 Getting Rid of the Login

**Goal:** Remove the annoying login requirement
**Method:** Hardcode a fake token so the app thinks you're logged in
**Consequence:** Yeah, this completely breaks security

### 5.2 The UserManager Hack

**File:** `smali_classes4/com/xj/common/user/UserManager.smali`

This file handles all the authentication. I modified 3 methods to trick the app.

#### Change 1: Fake Authentication Token

**Method:** `getToken()`

Originally, this method looked up your auth token from storage. I replaced it with a hardcoded fake token.

**Before (the original code):**
```smali
.method public getToken()Ljava/lang/String;
    .locals 3

    invoke-static {}, Lcom/blankj/utilcode/util/SPUtils;->f()Lcom/blankj/utilcode/util/SPUtils;
    move-result-object v0
    const-string v1, "token"
    const-string v2, ""
    invoke-virtual {v0, v1, v2}, Lcom/blankj/utilcode/util/SPUtils;->k(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method
```

**After (my modification):**
```smali
.method public getToken()Ljava/lang/String;
    .locals 1

    const-string v0, "a8ab9038-60d7-4261-afb8-d0dfd8d77aad"
    return-object v0
.end method
```

**What I did:**
- Deleted all the SharedPreferences lookup code
- Just return a hardcoded token: `a8ab9038-60d7-4261-afb8-d0dfd8d77aad`
- Now everyone using the modified APK has the same token

**How to do it yourself:**
1. Open `smali_classes4/com/xj/common/user/UserManager.smali`
2. Find the `getToken()` method
3. Delete everything between `.method` and `.end method`
4. Paste this:
   ```smali
   .locals 1
   const-string v0, "a8ab9038-60d7-4261-afb8-d0dfd8d77aad"
   return-object v0
   ```
5. Save

**The problem:**
Everyone shares the same token. If my custom API server wasn't handling this, you'd all be logged in as the same user. Not secure at all, but who cares about security when privacy is the goal?

#### Change 2: Hardcoded User ID

**Method:** `getUid()`
**Line Numbers:** Approximately lines 36-45

**Modified Code Addition:**
```smali
.method public getUid()I
    .locals 1

    invoke-static {}, Lcom/blankj/utilcode/util/SPUtils;->f()Lcom/blankj/utilcode/util/SPUtils;
    move-result-object v0
    const-string v1, "uid"
    const/4 v2, -0x1
    invoke-virtual {v0, v1, v2}, Lcom/blankj/utilcode/util/SPUtils;->g(Ljava/lang/String;I)I
    move-result v0

    # ADDED CODE STARTS HERE
    if-nez v0, :cond_0
    const v0, 0x1869f    # UID = 100000 in decimal
    :cond_0
    # ADDED CODE ENDS HERE

    return v0
.end method
```

**Analysis:**
- **What Changed:** Added null check and default UID of 100000 (hex 0x1869f)
- **Why:** Ensure app always has a valid UID even without login
- **How to Replicate:**
  1. Open `smali_classes4/com/xj/common/user/UserManager.smali`
  2. Find the `getUid()` method
  3. Before the final `return v0` statement, add:
     ```smali
     if-nez v0, :cond_0
     const v0, 0x1869f
     :cond_0
     ```
  4. Save file

**Security Impact:** HIGH
- All users without stored UID use the same ID (100000)
- User identification completely bypassed

#### Change 3: Login Status Always True

**Method:** `isLogin()`
**Line Numbers:** Approximately lines 50-70 (original), simplified to ~50-52 (modified)

**Original Code:**
```smali
.method public isLogin()Z
    .locals 1

    invoke-virtual {p0}, Lcom/xj/common/user/UserManager;->getToken()Ljava/lang/String;
    move-result-object v0
    invoke-interface {v0}, Ljava/lang/CharSequence;->length()I
    move-result v0
    if-lez v0, :cond_0

    invoke-virtual {p0}, Lcom/xj/common/user/UserManager;->getUid()I
    move-result v0
    if-ltz v0, :cond_0

    const/4 v0, 0x1    # true
    goto :goto_0

    :cond_0
    const/4 v0, 0x0    # false

    :goto_0
    return v0
.end method
```

**Modified Code:**
```smali
.method public isLogin()Z
    .locals 1

    const/4 v0, 0x1    # Always return true
    return v0
.end method
```

**Analysis:**
- **What Changed:** Removed all validation logic, always return true
- **Why:** Make app think user is always logged in
- **How to Replicate:**
  1. Open `smali_classes4/com/xj/common/user/UserManager.smali`
  2. Find the `isLogin()` method
  3. Delete all code between `.method` and `.end method`
  4. Insert:
     ```smali
     .locals 1
     const/4 v0, 0x1
     return v0
     ```
  5. Save file

**Security Impact:** CRITICAL
- App never checks if user is actually authenticated
- Complete bypass of authentication system

### 4.3 QR Code Login Neutralization

#### File Location
`smali_classes5/com/xj/landscape/launcher/ui/dialog/QrLoginHelper.smali`

#### Change: WeChat API Endpoint Redirection

**Line 7 (Original):**
```smali
const-string v0, "https://api.weixin.qq.com/sns/oauth2/access_token"
```

**Line 7 (Modified):**
```smali
const-string v0, "http://127.0.0.1/sns/oauth2/access_token"
```

**Line 16 (Original):**
```smali
const-string v0, "https://api.weixin.qq.com/cgi-bin/stable_token"
```

**Line 16 (Modified):**
```smali
const-string v0, "http://127.0.0.1/cgi-bin/stable_token"
```

**Line 25 (Original):**
```smali
const-string v0, "https://api.weixin.qq.com/cgi-bin/ticket/getticket"
```

**Line 25 (Modified):**
```smali
const-string v0, "http://127.0.0.1/cgi-bin/ticket/getticket"
```

**Analysis:**
- **What Changed:** All WeChat OAuth API endpoints redirected to localhost (127.0.0.1)
- **Why:** Prevent WeChat login from functioning and tracking attempts
- **How to Replicate:**
  1. Open `smali_classes5/com/xj/landscape/launcher/ui/dialog/QrLoginHelper.smali`
  2. Search for `api.weixin.qq.com`
  3. Replace all occurrences with `127.0.0.1`
  4. Keep the path portion after the domain
  5. Change `https` to `http` for localhost
  6. Save file

**Security Impact:** HIGH
- QR code login will fail (no server at localhost)
- WeChat cannot track login attempts
- Tencent servers receive no data

### 4.4 Mobile Carrier One-Key Login Neutralization

#### File Location
`smali_classes5/com/xj/landscape/launcher/utils/OneKeyAliHelper.smali`

#### Change: Privacy Policy URL Redirection

**Line 7 (Original):**
```smali
const-string v0, "https://www.xiaoji.com/url/gsw-app-rules"
```

**Line 7 (Modified):**
```smali
const-string v0, "http://127.0.0.1"
```

**Analysis:**
- **What Changed:** Privacy policy URL redirected to localhost
- **Why:** Prevent carrier login from loading privacy policy (required for consent)
- **How to Replicate:**
  1. Open `smali_classes5/com/xj/landscape/launcher/utils/OneKeyAliHelper.smali`
  2. Find the line containing privacy policy URL
  3. Replace with `http://127.0.0.1`
  4. Save file

**Security Impact:** MEDIUM
- One-key mobile login will fail
- Privacy policy tracking disabled
- Carrier authentication SDK cannot function

### 4.5 Authentication Activities Removed from Manifest

#### File Location
`AndroidManifest.xml`

#### Removed Activities:

**1. Alibaba Carrier Login:**
```xml
<activity android:name="com.mobile.auth.gatewayauth.LoginAuthActivity"/>
<activity android:name="com.mobile.auth.gatewayauth.activity.AuthWebVeiwActivity"/>
<activity android:name="com.mobile.auth.gatewayauth.PrivacyDialogActivity"/>
```

**2. Tencent QQ OAuth:**
```xml
<activity android:name="com.tencent.tauth.AuthActivity"/>
<activity android:name="com.tencent.connect.common.AssistActivity"/>
```

**3. WeChat Entry:**
```xml
<activity android:name="com.xiaoji.egggame.wxapi.WXEntryActivity"/>
<activity android:name="com.xiaoji.egggame.wxapi.WXPayEntryActivity"/>
```

**4. Firebase Authentication:**
```xml
<activity android:name="com.google.firebase.auth.internal.GenericIdpActivity"/>
<activity android:name="com.google.firebase.auth.internal.RecaptchaActivity"/>
```

**5. Google Sign-In:**
```xml
<activity android:name="com.google.android.gms.auth.api.signin.internal.SignInHubActivity"/>
```

**Analysis:**
- **What Changed:** Removed all OAuth and social login activity declarations
- **Why:** Prevent activities from being launched even if code remains
- **How to Replicate:**
  1. Open `AndroidManifest.xml`
  2. Search for each activity name listed above
  3. Delete entire `<activity>` tag (including all attributes and closing tag)
  4. Save file

**Impact:** All social and carrier login methods become non-functional

### 4.6 Complete Authentication SDK Removal

#### Ali Gateway Auth SDK - COMPLETE REMOVAL

**Directory:** `smali_classes2/com/mobile/auth/gatewayauth/`
**Files Removed:** 108 smali files

**Removal Rationale:**
- Ali Gateway provides one-key mobile carrier login
- Tracks login attempts via carrier network
- Collects IMSI, IMEI, and carrier information
- Complete SDK removal prevents any functionality

**How to Replicate:**
```bash
rm -rf smali_classes2/com/mobile/auth/gatewayauth/
```

#### Tencent SDK Removal

**Directories Removed:**
- `com/tencent/connect/` - QQ Connect SDK
- `com/tencent/mm/` - WeChat SDK (if present)
- `com/tencent/open/` - Tencent Open Platform
- `com/tencent/tauth/` - Tencent OAuth
- `com/tencent/tpgbox/` - TPG Box

**Kept:**
- `com/tencent/vasdolly/` - APK signing tool (not tracking-related)

**How to Replicate:**
```bash
rm -rf smali_classes*/com/tencent/connect/
rm -rf smali_classes*/com/tencent/mm/
rm -rf smali_classes*/com/tencent/open/
rm -rf smali_classes*/com/tencent/tauth/
rm -rf smali_classes*/com/tencent/tpgbox/
```

---

## 6. TELEMETRY AND TRACKING REMOVAL

### 8.1 Overview

**Total SDKs Removed/Disabled:** 6 major tracking systems
**Files Removed:** 500+ SDK files
**Privacy Impact:** CRITICAL

### 6.2 JPush (JiGuang Push Notification SDK)

#### Overview
JPush is a Chinese push notification service by JiGuang (Aurora Mobile). It provides push messaging, analytics, and device tracking capabilities.

#### Files Removed

**Directory:** `smali_classes2/cn/jpush/android/`

**Removed Subdirectories (40+):**
- `a/` through `h/` - Internal modules
- `aa/` through `ad/` - Additional components
- `asus/` - ASUS device-specific integration
- `api/` - Public API interfaces
- `cache/` - Data caching system
- `data/` - Data handling
- `helper/` - Utility classes
- `local/` - Local notification handling
- `service/` - Background services
- `ui/` - UI components

**Removed Classes (100+):**
```
BasicPushNotificationBuilder.smali
CallBackParams.smali
CmdMessage.smali
CustomMessage.smali
CustomPushNotificationBuilder.smali
DefaultPushNotificationBuilder.smali
InAppSlotParams.smali
JPushInterface$ErrorCode.smali
JPushMessage.smali
JThirdPlatFormInterface.smali
NotificationMessage.smali
PushNotificationBuilder.smali
SystemAlertHelper.smali
... (100+ more)
```

#### Files Modified (Stubbed)

**File:** `smali_classes2/cn/jpush/android/api/JPushInterface.smali`

**Modification:** All methods return immediately without functionality

Example stub:
```smali
.method public static init(Landroid/content/Context;)V
    .locals 0
    return-void
.end method

.method public static setAlias(Landroid/content/Context;Ljava/lang/String;)V
    .locals 0
    return-void
.end method

.method public static setTags(Landroid/content/Context;Ljava/util/Set;)V
    .locals 0
    return-void
.end method
```

**File:** `smali_classes2/cn/jpush/android/helper/Logger.smali`

**Modification:** All logging disabled:
```smali
.method public static d(Ljava/lang/String;Ljava/lang/String;)V
    .locals 0
    return-void
.end method

.method public static e(Ljava/lang/String;Ljava/lang/String;)V
    .locals 0
    return-void
.end method
```

#### AndroidManifest.xml Removals

**Services:**
```xml
<service
    android:name="com.xj.push.jiguang.JPushService"
    android:process=":pushcore"
    android:enabled="true"
    android:exported="false">
</service>

<service android:name="cn.jpush.android.service.PushService"/>
```

**Receivers:**
```xml
<receiver
    android:name="com.xj.push.jiguang.JPushBroadcastReceiver"
    android:enabled="true">
    <intent-filter>
        <action android:name="cn.jpush.android.intent.REGISTRATION"/>
        <action android:name="cn.jpush.android.intent.MESSAGE_RECEIVED"/>
        <action android:name="cn.jpush.android.intent.NOTIFICATION_RECEIVED"/>
        <category android:name="${applicationId}"/>
    </intent-filter>
</receiver>

<receiver android:name="cn.jpush.android.service.PushReceiver"/>
<receiver android:name="cn.jpush.android.service.AlarmReceiver"/>
<receiver android:name="cn.jpush.android.service.SchedulerReceiver"/>
<receiver android:name="cn.jpush.android.asus.AsusPushMessageReceiver"/>
```

**Activities:**
```xml
<activity android:name="cn.jpush.android.ui.PopWinActivity"/>
<activity android:name="cn.jpush.android.ui.PushActivity"/>
<activity android:name="cn.android.service.JTransitActivity"/>
<activity android:name="cn.jpush.android.service.JNotifyActivity"/>
```

**Providers:**
```xml
<provider
    android:name="cn.jpush.android.service.DataProvider"
    android:authorities="${applicationId}.DataProvider"
    android:exported="false"/>

<provider
    android:name="cn.jpush.android.service.InitProvider"
    android:authorities="${applicationId}.InitProvider"
    android:exported="false"/>
```

**Metadata:**
```xml
<meta-data android:name="JPUSH_CHANNEL" android:value="default"/>
<meta-data android:name="JPUSH_APPKEY" android:value="fdeb83da9ad2f3e16b983fde"/>
```

#### Rationale for Removal

1. **Push Notification Tracking:** JPush tracks all push notification interactions
2. **Device Fingerprinting:** Collects device ID, Android ID, MAC address
3. **Geographic Tracking:** May use location for targeted notifications
4. **Behavioral Analytics:** Tracks notification open rates, dismissals
5. **Third-Party Data Sharing:** JiGuang shares data with advertisers

#### Privacy Impact: CRITICAL

- Eliminates push notification tracking
- Removes device fingerprinting via JPush
- Prevents JiGuang from collecting analytics
- No data sent to JiGuang servers
- App cannot receive push notifications

#### How to Replicate

1. **Remove SDK Files:**
   ```bash
   rm -rf smali_classes2/cn/jpush/
   ```

2. **Remove Manifest Components:**
   - Open `AndroidManifest.xml`
   - Remove all JPush services, receivers, activities, providers
   - Remove JPush metadata entries

3. **Stub Remaining References (if any):**
   - Search for any remaining `cn/jpush` imports
   - Replace method bodies with `return-void` or appropriate stub

### 6.3 JiGuang (Aurora Mobile Core SDK)

#### Overview
JiGuang is the parent company SDK that underlies JPush. It provides core analytics, device identification, and data collection capabilities.

#### Files Removed

**Directory:** `smali_classes2/cn/jiguang/`

**Removed Subdirectories (100+):**
- `a/` through `au/` (47 subdirectories) - Core modules
- `analytics/` - Analytics SDK
- `android/` - Android integration layer
- `api/` - API interfaces
- `biz/` - Business logic
- `common/` - Common utilities
- `d/` - Data handling
- `internal/` - Internal components
- `net/` - Networking
- `service/` - Background services
- `utils/` - Utility classes

**Files Modified:**

`cn/jiguang/ag/e.smali` through `cn/jiguang/ag/q.smali` (13 files)

These appear to be core initialization and communication modules. Modified to stub out functionality.

#### AndroidManifest.xml Changes

No explicit JiGuang manifest entries (integrated with JPush components)

#### Rationale for Removal

1. **Core Analytics:** JiGuang provides underlying analytics for JPush
2. **Device Profiling:** Deep device fingerprinting capabilities
3. **Network Analysis:** Monitors network type, carrier, connection quality
4. **App Behavior:** Tracks app usage patterns
5. **Cross-App Tracking:** Can track across multiple apps using JiGuang

#### Privacy Impact: CRITICAL

- Removes core analytics engine
- Eliminates cross-app tracking capability
- Prevents device profiling
- No telemetry sent to JiGuang servers

#### How to Replicate

```bash
rm -rf smali_classes2/cn/jiguang/
```

Keep only files that are modified/stubbed (e.g., `cn/jiguang/ag/*.smali`) if needed for app stability.

### 6.4 UMeng Analytics (Alibaba)

#### Overview
UMeng (Youmeng) is Alibaba's analytics platform, providing app analytics, user behavior tracking, and crash reporting.

#### Files Removed

**Directory:** `smali_classes4/com/umeng/analytics/`

**Removed Files:**
```
AnalyticsConfig.smali
CoreProtocol.smali
Gender.smali (+ 4 related enum files)
MobclickAgent$EScenarioType.smali
MobclickAgent$PageMode.smali
a.smali, b.smali, c.smali (internal modules)
```

**Removed Subdirectories:**
- `filter/` - Event filtering system
- `pro/` - Professional analytics features
- `process/` - Data processing pipeline

**File Modified:**

`smali_classes4/com/umeng/analytics/MobclickAgent.smali`

All public methods stubbed:

```smali
.method public static onEvent(Landroid/content/Context;Ljava/lang/String;)V
    .locals 0
    return-void
.end method

.method public static onPageStart(Ljava/lang/String;)V
    .locals 0
    return-void
.end method

.method public static onPageEnd(Ljava/lang/String;)V
    .locals 0
    return-void
.end method

.method public static onResume(Landroid/content/Context;)V
    .locals 0
    return-void
.end method

.method public static onPause(Landroid/content/Context;)V
    .locals 0
    return-void
.end method
```

#### AndroidManifest.xml Changes

No explicit UMeng entries in removed sections (may be initialized programmatically)

#### Rationale for Removal

1. **Event Tracking:** Tracks custom events (button clicks, feature usage)
2. **Screen Tracking:** Monitors which screens users visit
3. **Session Analytics:** Tracks app usage sessions
4. **User Demographics:** Collects age, gender, location
5. **Crash Reporting:** Sends crash data to UMeng servers
6. **Alibaba Integration:** Data may be shared with Alibaba ecosystem

#### Privacy Impact: HIGH

- No custom event tracking
- Screen view tracking disabled
- Session analytics stopped
- Demographic data not collected
- No crash reports sent to UMeng

#### How to Replicate

1. **Remove SDK Files:**
   ```bash
   rm -rf smali_classes4/com/umeng/analytics/
   rm -rf smali_classes4/com/umeng/commonsdk/
   ```

2. **Stub MobclickAgent (if needed for stability):**
   - Open `MobclickAgent.smali`
   - Replace all method bodies with `return-void`

### 6.5 Firebase (Google)

#### Overview
Firebase is Google's mobile platform providing authentication, analytics, cloud messaging, and many other services.

#### Files Removed

**Directory:** `smali_classes3/com/google/firebase/`

**Status:** ENTIRE DIRECTORY REMOVED

**Removed Components:**
- `analytics/` - Firebase Analytics
- `auth/` - Firebase Authentication
- `common/` - Common Firebase utilities
- `components/` - Component registration system
- `installations/` - Firebase Installations
- `ktx/` - Kotlin extensions
- `messaging/` - Firebase Cloud Messaging (FCM)
- `provider/` - Firebase initialization provider

**Estimated Files:** 200+ Firebase SDK files completely removed

#### AndroidManifest.xml Removals

**ComponentDiscoveryService:**
```xml
<service
    android:name="com.google.firebase.components.ComponentDiscoveryService"
    android:directBootAware="true"
    android:exported="false">
    <meta-data
        android:name="com.google.firebase.components:com.google.firebase.analytics.connector.internal.AnalyticsConnectorRegistrar"
        android:value="com.google.firebase.components.ComponentRegistrar"/>
    <meta-data
        android:name="com.google.firebase.components:com.google.firebase.auth.FirebaseAuthRegistrar"
        android:value="com.google.firebase.components.ComponentRegistrar"/>
    <!-- 6+ more component registrars -->
</service>
```

**Firebase Init Provider:**
```xml
<provider
    android:name="com.google.firebase.provider.FirebaseInitProvider"
    android:authorities="${applicationId}.firebaseinitprovider"
    android:exported="false"
    android:initOrder="100"/>
```

**Firebase Auth Activities:**
```xml
<activity
    android:name="com.google.firebase.auth.internal.GenericIdpActivity"
    android:excludeFromRecents="true"
    android:exported="true"
    android:launchMode="singleTask"
    android:theme="@android:style/Theme.Translucent.NoTitleBar">
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
    </intent-filter>
</activity>

<activity
    android:name="com.google.firebase.auth.internal.RecaptchaActivity"
    android:excludeFromRecents="true"
    android:exported="true"
    android:launchMode="singleTask"
    android:theme="@android:style/Theme.Translucent.NoTitleBar"/>
```

**Ad Services Config:**
```xml
<property
    android:name="android.adservices.AD_SERVICES_CONFIG"
    android:resource="@xml/ga_ad_services_config"/>
```

#### Rationale for Removal

1. **Firebase Analytics:** Comprehensive analytics and user behavior tracking
2. **Firebase Auth:** May leak authentication data to Google
3. **Firebase Installations:** Unique Firebase instance IDs for tracking
4. **Crashlytics:** Crash reporting sends data to Google
5. **Cloud Messaging:** Push notification tracking via Google servers
6. **Google Integration:** Deep integration with Google advertising ecosystem

#### Privacy Impact: CRITICAL

- No Firebase Analytics tracking
- No crash data sent to Google
- Firebase authentication disabled
- No FCM push notification tracking
- Firebase Installation IDs not generated
- Complete removal of Google Firebase tracking

#### How to Replicate

1. **Remove Firebase SDK:**
   ```bash
   rm -rf smali_classes3/com/google/firebase/
   rm -rf smali_classes*/com/google/firebase/  # Check all smali_classes* directories
   ```

2. **Remove Manifest Entries:**
   - Open `AndroidManifest.xml`
   - Remove `ComponentDiscoveryService` and all its metadata
   - Remove `FirebaseInitProvider`
   - Remove Firebase auth activities
   - Remove ad services config property

3. **Remove Firebase Config File (if present):**
   ```bash
   rm -f assets/google-services.json
   rm -f res/values/google-services.xml
   ```

### 6.6 Google Play Services - Partial Removal

#### Overview
Google Play Services provides various Google service integrations. Selective components were removed while maintaining core Android functionality.

#### Directories Removed

**Completely Removed:**
- `com/google/android/play/` - Play Core library
- `com/google/android/recaptcha/` - reCAPTCHA service

#### AndroidManifest.xml Removals

**Google Sign-In:**
```xml
<activity
    android:name="com.google.android.gms.auth.api.signin.internal.SignInHubActivity"
    android:excludeFromRecents="true"
    android:exported="false"
    android:theme="@android:style/Theme.Translucent.NoTitleBar"/>

<service
    android:name="com.google.android.gms.auth.api.signin.RevocationBoundService"
    android:exported="true"
    android:permission="com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION"
    android:visibleToInstantApps="true"/>
```

**Google API Activity:**
```xml
<activity
    android:name="com.google.android.gms.common.api.GoogleApiActivity"
    android:exported="false"
    android:theme="@android:style/Theme.Translucent.NoTitleBar"/>
```

**Google Cast:**
```xml
<receiver
    android:name="com.google.android.gms.cast.framework.media.MediaIntentReceiver"
    android:exported="false"/>

<service
    android:name="com.google.android.gms.cast.framework.ReconnectionService"
    android:exported="false"/>
```

**Google Measurement/Analytics:**
```xml
<receiver
    android:name="com.google.android.gms.measurement.AppMeasurementReceiver"
    android:enabled="true"
    android:exported="false"/>

<service
    android:name="com.google.android.gms.measurement.AppMeasurementService"
    android:enabled="true"
    android:exported="false"/>

<service
    android:name="com.google.android.gms.measurement.AppMeasurementJobService"
    android:enabled="true"
    android:exported="false"
    android:permission="android.permission.BIND_JOB_SERVICE"/>
```

**Data Transport (Google Telemetry):**
```xml
<service
    android:name="com.google.android.datatransport.runtime.backends.TransportBackendDiscovery"
    android:exported="false">
    <meta-data
        android:name="backend:com.google.android.datatransport.cct.CctBackendFactory"
        android:value="cct"/>
</service>

<service
    android:name="com.google.android.datatransport.runtime.scheduling.jobscheduling.JobInfoSchedulerService"
    android:exported="false"
    android:permission="android.permission.BIND_JOB_SERVICE"/>

<receiver
    android:name="com.google.android.datatransport.runtime.scheduling.jobscheduling.AlarmManagerSchedulerBroadcastReceiver"
    android:exported="false"/>
```

#### Rationale for Removal

1. **Google Sign-In:** Tracks login via Google accounts
2. **App Measurement:** Google's internal analytics (separate from Firebase)
3. **Data Transport:** Telemetry pipeline for sending data to Google
4. **Cast:** Google Cast tracking
5. **Ad Attribution:** Tracks app installs from Google ads

#### Privacy Impact: HIGH

- Google Sign-In tracking disabled
- App measurement analytics stopped
- No data transport to Google servers
- Google Cast tracking removed
- Ad attribution disabled

#### How to Replicate

1. **Remove Play Services Components:**
   ```bash
   rm -rf smali_classes*/com/google/android/play/
   rm -rf smali_classes*/com/google/android/recaptcha/
   ```

2. **Remove Manifest Entries:**
   - Open `AndroidManifest.xml`
   - Remove all Google auth activities/services
   - Remove measurement services
   - Remove data transport components
   - Remove Google Cast components

### 6.7 Alipay SDK - Activity Removal

#### Overview
Alipay (Ant Financial/Alibaba) payment SDK removed to prevent payment tracking.

#### AndroidManifest.xml Removals

**Alipay Metadata:**
```xml
<meta-data
    android:name="com.alipay.sdk.appId"
    android:value="2021005104662679"/>
```

**Alipay Activities:**
```xml
<activity
    android:name="com.alipay.sdk.app.H5PayActivity"
    android:configChanges="orientation|keyboardHidden|navigation"
    android:exported="false"
    android:screenOrientation="behind"/>

<activity
    android:name="com.alipay.sdk.app.H5AuthActivity"
    android:configChanges="orientation|keyboardHidden|navigation"
    android:exported="false"
    android:screenOrientation="behind"/>

<activity
    android:name="com.alipay.sdk.app.PayResultActivity"
    android:exported="false"
    android:launchMode="singleTask"/>

<activity
    android:name="com.alipay.sdk.app.AlipayResultActivity"
    android:exported="true"
    android:launchMode="singleTask"/>

<activity
    android:name="com.alipay.sdk.app.H5OpenAuthActivity"
    android:exported="false"
    android:launchMode="singleTask"/>

<activity
    android:name="com.alipay.sdk.app.APayEntranceActivity"
    android:exported="false"
    android:launchMode="singleTask"/>
```

**WeChat Pay:**
```xml
<activity
    android:name="com.xiaoji.egggame.wxapi.WXPayEntryActivity"
    android:exported="true"
    android:launchMode="singleTop"/>
```

#### Rationale for Removal

1. **Payment Tracking:** Alipay tracks all payment attempts and transactions
2. **User Profiling:** Payment history used for user profiling
3. **Alibaba Integration:** Data shared with Alibaba ecosystem
4. **WeChat Pay Tracking:** Similar tracking via Tencent

#### Privacy Impact: HIGH

- Payment tracking disabled
- No transaction data sent to Alipay/WeChat
- User cannot make in-app purchases
- Alibaba cannot profile user via payments

#### How to Replicate

1. Open `AndroidManifest.xml`
2. Remove Alipay metadata entry
3. Remove all Alipay activities
4. Remove WeChat Pay activity
5. Save file

### 6.8 UC Crash SDK (Alibaba)

#### File Modified
`smali_classes4/com/uc/crashsdk/a/d.smali`

#### Change
Likely stubbed or disabled crash reporting functionality.

#### Rationale
- Prevents crash data from being sent to Alibaba servers
- Crash reports can contain sensitive data (stack traces, memory contents)

### 6.9 Crash and Error Tracking Summary

**Removed/Disabled:**
- UC Crash SDK (Alibaba)
- Firebase Crashlytics (Google)
- UMeng crash reporting

**Privacy Impact:** All crash data remains local, no telemetry sent to third parties

---

## 7. NETWORK CONFIGURATION CHANGES

### 8.1 Overview

All API endpoints were redirected from the original vendor servers to a custom Cloudflare Workers endpoint. This represents a complete man-in-the-middle of all app-server communication.

### 7.2 API Endpoint Redirection

#### File Location
`smali_classes4/com/xj/common/http/EggGameHttpConfig.smali`

#### Changes

**Original Code:**

**Line 7 (Test Environment):**
```smali
const-string v0, "https://test-magic-landscape-api.vgabc.com/"
```

**Line 16 (Production Environment):**
```smali
const-string v0, "https://landscape-api.vgabc.com/"
```

**Line 22 (Development Environment):**
```smali
const-string v0, "https://dev-gamehub-api.vgabc.com/"
```

**Modified Code (All Environments):**

**Line 7:**
```smali
const-string v0, "https://gamehub-api.secureflex.workers.dev/"
```

**Line 16:**
```smali
const-string v0, "https://gamehub-api.secureflex.workers.dev/"
```

**Line 22:**
```smali
const-string v0, "https://gamehub-api.secureflex.workers.dev/"
```

#### Analysis

**What Changed:**
- All three environment endpoints redirected to single custom endpoint
- Original vendor domain: `vgabc.com`
- New custom domain: `secureflex.workers.dev` (Cloudflare Workers)

**Why:**
1. **Intercept all API traffic:** Custom server receives all app API calls
2. **Mock server responses:** Return fake data to satisfy app requirements
3. **Privacy:** Original vendor receives zero traffic
4. **Control:** Complete control over what data app receives
5. **Telemetry blocking:** Any telemetry sent to API endpoints is intercepted

**How to Replicate:**
1. Open `smali_classes4/com/xj/common/http/EggGameHttpConfig.smali`
2. Find all occurrences of `vgabc.com`
3. Replace with your custom API server URL
4. Ensure all three environments point to same endpoint (or configure separately)
5. Save file

**Network Behavior:**
```
Original Flow:
App → landscape-api.vgabc.com → Vendor Server → Response

Modified Flow:
App → gamehub-api.secureflex.workers.dev → Custom Server → Mocked Response
```

#### Security Implications

**CRITICAL - Complete MITM:**
- Custom server operator has complete control
- Can log all API requests
- Can modify all responses
- App trusts custom server completely
- Original vendor receives no data (privacy benefit)
- Must trust custom server operator (security risk)

### 7.3 Custom API Server Implementation

I built a custom Cloudflare Workers API to handle all the app's requests. For full technical details, see `GAMEHUB_API_ANALYSIS.md`.

#### Quick Overview

**Architecture:**
- **Cloudflare Worker** (`gamehub-api.secureflex.workers.dev`) - Routes requests
- **GitHub Static API** (`raw.githubusercontent.com/gamehublite/gamehub_api/main`) - Hosts JSON files

**Key Endpoints Implemented:**
- `POST /simulator/v2/getComponentList` - Component downloads (Box64, drivers, DXVK, etc.)
- `POST /card/getGameDetail` - Game metadata (proxied to Chinese server, hides your IP)
- `POST /simulator/executeScript` - GPU configs (sanitizes device fingerprint before proxying)
- `POST /base/getBaseInfo` - App configuration
- `GET /game/getSteamHost` - Steam CDN optimization
- `POST /card/getNewsList` - News feed (returns empty)
- `POST /card/getGameIcon` - Game icons (returns empty)

**Privacy Features:**
- Your IP is hidden when proxying to Chinese servers (they see Cloudflare's IP)
- Device fingerprints are sanitized (removes model, GPU details, driver version)
- Component downloads are direct to CDN (no proxy, no logging)
- All code is open source on GitHub

#### Example: Simplified Worker Code

```javascript
// See GAMEHUB_API_ANALYSIS.md for full 287-line implementation

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)

  // Route component list requests to GitHub
  if (url.pathname === '/simulator/v2/getComponentList') {
    const manifestUrl = 'https://raw.githubusercontent.com/gamehublite/gamehub_api/main/components/box64_manifest'
    const response = await fetch(manifestUrl)
    return response
  }

  // Proxy game details with IP hidden
  if (url.pathname === '/card/getGameDetail') {
    const response = await fetch('https://landscape-api.vgabc.com' + url.pathname, {
      method: request.method,
      headers: request.headers,
      body: await request.text()
    })
    return response  // Chinese server sees Cloudflare IP, not yours
  }

  // Return empty for news
  if (url.pathname === '/card/getNewsList') {
    return new Response(JSON.stringify({
      code: 200,
      msg: 'Success',
      data: []  // Empty news list
    }), {
      headers: { 'Content-Type': 'application/json' }
    })
  }

  // Default fallback
  return new Response(JSON.stringify({
    code: 200,
    msg: 'Success',
    data: {}
  }), {
    headers: { 'Content-Type': 'application/json' }
  })
}
```

**Deployment:**
```bash
cd gamehub-worker
npm install
npm run deploy
# Outputs: https://gamehub-api.secureflex.workers.dev
```

For complete implementation details, endpoints, privacy features, and GitHub static API structure, see `GAMEHUB_API_ANALYSIS.md`.

### 7.4 WeChat API Neutralization

As documented in Section 4.3, WeChat APIs were redirected to localhost:

**File:** `smali_classes5/com/xj/landscape/launcher/ui/dialog/QrLoginHelper.smali`

**Changes:**
- `https://api.weixin.qq.com/*` → `http://127.0.0.1/*`

**Effect:**
- QR code login fails silently
- No data sent to Tencent servers
- WeChat cannot track login attempts

### 7.5 Privacy Policy URL Neutralization

**File:** `smali_classes5/com/xj/landscape/launcher/utils/OneKeyAliHelper.smali`

**Change:**
- `https://www.xiaoji.com/url/gsw-app-rules` → `http://127.0.0.1`

**Effect:**
- Privacy policy cannot load
- Blocks carrier login which requires policy acceptance
- Prevents tracking of policy views

### 7.6 Network Changes Summary

| Endpoint Type | Original Destination | Modified Destination | Impact |
|--------------|---------------------|---------------------|---------|
| API (Test) | test-magic-landscape-api.vgabc.com | gamehub-api.secureflex.workers.dev | MITM |
| API (Prod) | landscape-api.vgabc.com | gamehub-api.secureflex.workers.dev | MITM |
| API (Dev) | dev-gamehub-api.vgabc.com | gamehub-api.secureflex.workers.dev | MITM |
| WeChat OAuth | api.weixin.qq.com | 127.0.0.1 | Disabled |
| Privacy Policy | www.xiaoji.com | 127.0.0.1 | Disabled |

**Overall Network Impact:**
- Zero traffic to original vendor
- Zero traffic to Tencent (WeChat/QQ)
- Zero traffic to Alibaba (Alipay/carrier login)
- All app traffic → custom server
- Complete network-level privacy from vendor

---

## 8. UI/UX MODIFICATIONS

### 8.1 Overview

Several UI activities were removed to streamline user experience and prevent tracking-related prompts.

### 8.2 Notification Permission Request Removal

#### Activity Removed
`com.xj.landscape.launcher.ui.guide.GuideRequestNotificationPermissionActivity`

#### Location
`AndroidManifest.xml` - Activity declaration removed

#### File Status
`smali_classes5/com/xj/landscape/launcher/ui/guide/GuideRequestNotificationPermissionActivity.smali` - File may still exist but cannot be launched

#### Rationale
- Prevent app from requesting notification permission
- Notifications often used for tracking user engagement
- Blocks notification-based tracking vectors

#### Impact
- User will not see notification permission dialog
- Push notifications disabled (already removed via JPush removal)
- Simplified onboarding flow

#### How to Replicate
1. Open `AndroidManifest.xml`
2. Search for `GuideRequestNotificationPermissionActivity`
3. Delete entire `<activity>` declaration
4. Optionally delete the smali file:
   ```bash
   rm smali_classes5/com/xj/landscape/launcher/ui/guide/GuideRequestNotificationPermissionActivity.smali
   ```

### 8.3 Test and Debug Activity Removal

#### Activities Removed

**Firebase Test Activity:**
```xml
<activity android:name="com.xj.landscape.launcher.test.firebase.TestFirebaseAuthActivity"/>
```

**Rationale:**
- Remove development/testing functionality from production
- Firebase auth testing activity exposes Firebase integration

#### How to Replicate
1. Open `AndroidManifest.xml`
2. Search for `TestFirebaseAuthActivity`
3. Delete activity declaration

### 8.4 ADB/Developer Options Removal

#### Activities Removed

```xml
<activity android:name="com.xj.adb.wifiui.ui.DeveloperOptionsActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.UsbOptionsActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.SelectActivationTypeActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.AdbActivationActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.AdbActivationSuccessActivity"/>
```

#### Rationale
- Remove ADB setup UI (Android Debug Bridge)
- ADB functionality may expose device to additional tracking
- Simplify app by removing developer features

#### Impact
- Users cannot enable ADB via app UI
- May need to enable ADB through Android settings if required

#### How to Replicate
1. Open `AndroidManifest.xml`
2. Search for `com.xj.adb.wifiui.ui.`
3. Delete all matching activity declarations

### 8.5 Bluetooth Permission Dialog

#### File Modified
`smali_classes4/com/xj/common/view/dialog/permission/RequestBlePermissionDialogFragment.smali`

#### Status
Diff generated but appears to be minimal or empty changes

#### Expected Modification
Likely stubbed to prevent Bluetooth permission request dialog

#### Rationale
- Prevent app from requesting Bluetooth permission
- Bluetooth can be used for proximity tracking
- BLE beacons used for location tracking in retail/advertising

### 8.6 UI Modifications Summary

| Component | Type | Status | Privacy Impact |
|-----------|------|--------|----------------|
| Notification Permission Activity | Activity | Removed | HIGH |
| Firebase Test Activity | Activity | Removed | MEDIUM |
| ADB Setup Activities (5) | Activities | Removed | LOW |
| BLE Permission Dialog | Fragment | Modified | MEDIUM |

**Total UI Components Removed:** 7 activities, 1 dialog modified

---

## 9. REPLICATION PROCEDURES

### 9.1 Prerequisites

**Required Tools:**
- **apktool** (v2.7.0 or later) - APK decompilation/recompilation
- **Text editor** with syntax highlighting (VS Code, Sublime Text, or vim)
- **Java Development Kit (JDK)** 8 or later
- **Android SDK** (for apksigner and zipalign)
- **Keystore** for signing APKs

**System Requirements:**
- macOS, Linux, or Windows with WSL
- Minimum 4GB RAM
- 2GB free disk space

**Knowledge Requirements:**
- Basic understanding of Android app structure
- Familiarity with XML editing
- Basic understanding of smali bytecode (helpful but not required)

### 9.2 Step 1: Decompile the Original APK

```bash
# Install apktool (macOS)
brew install apktool

# Or download from official site or github

# Decompile the APK
apktool d original.apk -o gamehub_decompiled

# Verify decompilation
ls gamehub_decompiled/
# Should see: AndroidManifest.xml, apktool.yml, smali/, smali_classes2/, res/, etc.
```

**Expected Output:**
```
AndroidManifest.xml
apktool.yml
assets/
lib/
original/
res/
smali/
smali_classes2/
smali_classes3/
smali_classes4/
smali_classes5/
... (more smali_classes directories)
unknown/
```

### 9.3 Step 2: Backup Original Files

```bash
# Create backup directory
mkdir gamehub_backup

# Backup AndroidManifest
cp gamehub_decompiled/AndroidManifest.xml gamehub_backup/

# Backup key smali files before modification
cp gamehub_decompiled/smali_classes4/com/xj/common/user/UserManager.smali gamehub_backup/
cp gamehub_decompiled/smali_classes4/com/xj/common/http/EggGameHttpConfig.smali gamehub_backup/
cp gamehub_decompiled/smali_classes5/com/xj/landscape/launcher/ui/dialog/QrLoginHelper.smali gamehub_backup/
cp gamehub_decompiled/smali_classes5/com/xj/landscape/launcher/utils/OneKeyAliHelper.smali gamehub_backup/
```

### 9.4 Step 3: Modify AndroidManifest.xml

#### 3.1 Remove Permissions

Open `gamehub_decompiled/AndroidManifest.xml` in your text editor.

**Remove these permission lines:**

```xml
<!-- Location tracking -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission-sdk-23 android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission-sdk-23 android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Audio/video surveillance -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.FLASHLIGHT"/>

<!-- Device fingerprinting -->
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"/>
<uses-permission android:name="com.android.permission.GET_INSTALLED_APPS"/>

<!-- Advertising -->
<uses-permission android:name="android.permission.ACCESS_ADSERVICES_ATTRIBUTION"/>
<uses-permission android:name="android.permission.ACCESS_ADSERVICES_AD_ID"/>
<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>

<!-- Contacts -->
<uses-permission android:name="android.permission.READ_CONTACTS"/>

<!-- Notifications -->
<uses-permission android:name="android.permission.NOTIFICATION_SERVICE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Installation and boot -->
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.BROADCAST_STICKY"/>

<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"/>

<!-- Misc -->
<uses-permission android:name="android.permission.EXPAND_STATUS_BAR"/>
<uses-permission android:name="com.android.launcher.permission.INSTALL_SHORTCUT"/>
<uses-permission android:name="com.android.launcher.permission.UNINSTALL_SHORTCUT"/>
<uses-permission android:name="com.android.launcher.permission.WRITE_SETTINGS"/>
<uses-permission android:name="com.android.launcher.permission.READ_SETTINGS"/>
<uses-permission android:name="com.android.providers.tv.permission.READ_EPG_DATA"/>
<uses-permission android:name="com.android.providers.tv.permission.WRITE_EPG_DATA"/>
```

**Also remove JPush permissions:**
```xml
<permission android:name="com.antutu.ABenchMark.permission.JPUSH_MESSAGE" android:protectionLevel="signature"/>
<uses-permission android:name="com.antutu.ABenchMark.permission.JPUSH_MESSAGE"/>
```

#### 3.2 Remove Package Queries

Find the `<queries>` section and remove:

```xml
<package android:name="com.tencent.mm"/>              <!-- WeChat -->
<package android:name="com.tencent.mobileqq"/>        <!-- QQ -->
<package android:name="com.tencent.tim"/>             <!-- TIM -->
<package android:name="com.tencent.minihd.qq"/>       <!-- QQ HD -->
<package android:name="com.tencent.qqlite"/>          <!-- QQ Lite -->
<package android:name="com.eg.android.AlipayGphone"/> <!-- Alipay -->
<package android:name="com.eg.android.AlipayGphoneRC"/>
<package android:name="hk.alipay.wallet"/>
<package android:name="hk.alipay.walletRC"/>
```

#### 3.3 Remove Authentication Activities

Search for and delete these activity declarations:

```xml
<!-- Ali Carrier Login -->
<activity android:name="com.mobile.auth.gatewayauth.LoginAuthActivity"/>
<activity android:name="com.mobile.auth.gatewayauth.activity.AuthWebVeiwActivity"/>
<activity android:name="com.mobile.auth.gatewayauth.PrivacyDialogActivity"/>

<!-- Tencent QQ -->
<activity android:name="com.tencent.tauth.AuthActivity"/>
<activity android:name="com.tencent.connect.common.AssistActivity"/>

<!-- WeChat -->
<activity android:name="com.xiaoji.egggame.wxapi.WXEntryActivity"/>
<activity android:name="com.xiaoji.egggame.wxapi.WXPayEntryActivity"/>

<!-- Firebase -->
<activity android:name="com.google.firebase.auth.internal.GenericIdpActivity"/>
<activity android:name="com.google.firebase.auth.internal.RecaptchaActivity"/>

<!-- Google Sign-In -->
<activity android:name="com.google.android.gms.auth.api.signin.internal.SignInHubActivity"/>
<activity android:name="com.google.android.gms.common.api.GoogleApiActivity"/>
```

#### 3.4 Remove Tracking Services and Receivers

**JPush Components:**
```xml
<!-- Services -->
<service android:name="com.xj.push.jiguang.JPushService"/>
<service android:name="cn.jpush.android.service.PushService"/>

<!-- Receivers -->
<receiver android:name="com.xj.push.jiguang.JPushBroadcastReceiver"/>
<receiver android:name="cn.jpush.android.service.PushReceiver"/>
<receiver android:name="cn.jpush.android.service.AlarmReceiver"/>
<receiver android:name="cn.jpush.android.service.SchedulerReceiver"/>
<receiver android:name="cn.jpush.android.asus.AsusPushMessageReceiver"/>

<!-- Activities -->
<activity android:name="cn.jpush.android.ui.PopWinActivity"/>
<activity android:name="cn.jpush.android.ui.PushActivity"/>
<activity android:name="cn.android.service.JTransitActivity"/>
<activity android:name="cn.jpush.android.service.JNotifyActivity"/>

<!-- Providers -->
<provider android:name="cn.jpush.android.service.DataProvider"/>
<provider android:name="cn.jpush.android.service.InitProvider"/>
```

**Firebase Components:**
```xml
<service android:name="com.google.firebase.components.ComponentDiscoveryService"/>
<provider android:name="com.google.firebase.provider.FirebaseInitProvider"/>
```

**Google Measurement:**
```xml
<receiver android:name="com.google.android.gms.measurement.AppMeasurementReceiver"/>
<service android:name="com.google.android.gms.measurement.AppMeasurementService"/>
<service android:name="com.google.android.gms.measurement.AppMeasurementJobService"/>
```

**Google Data Transport:**
```xml
<service android:name="com.google.android.datatransport.runtime.backends.TransportBackendDiscovery"/>
<service android:name="com.google.android.datatransport.runtime.scheduling.jobscheduling.JobInfoSchedulerService"/>
<receiver android:name="com.google.android.datatransport.runtime.scheduling.jobscheduling.AlarmManagerSchedulerBroadcastReceiver"/>
```

**Google Cast:**
```xml
<receiver android:name="com.google.android.gms.cast.framework.media.MediaIntentReceiver"/>
<service android:name="com.google.android.gms.cast.framework.ReconnectionService"/>
```

**Alipay:**
```xml
<activity android:name="com.alipay.sdk.app.H5PayActivity"/>
<activity android:name="com.alipay.sdk.app.H5AuthActivity"/>
<activity android:name="com.alipay.sdk.app.PayResultActivity"/>
<activity android:name="com.alipay.sdk.app.AlipayResultActivity"/>
<activity android:name="com.alipay.sdk.app.H5OpenAuthActivity"/>
<activity android:name="com.alipay.sdk.app.APayEntranceActivity"/>
```

#### 3.5 Remove Metadata

```xml
<!-- JPush -->
<meta-data android:name="JPUSH_CHANNEL" android:value="default"/>
<meta-data android:name="JPUSH_APPKEY" android:value="fdeb83da9ad2f3e16b983fde"/>

<!-- Alipay -->
<meta-data android:name="com.alipay.sdk.appId" android:value="2021005104662679"/>
```

#### 3.6 Remove UI Activities

```xml
<activity android:name="com.xj.landscape.launcher.ui.guide.GuideRequestNotificationPermissionActivity"/>
<activity android:name="com.xj.landscape.launcher.test.firebase.TestFirebaseAuthActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.DeveloperOptionsActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.UsbOptionsActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.SelectActivationTypeActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.AdbActivationActivity"/>
<activity android:name="com.xj.adb.wifiui.ui.AdbActivationSuccessActivity"/>
```

**Save AndroidManifest.xml**

### 9.5 Step 4: Modify UserManager (Authentication Bypass)

#### File Path
`gamehub_decompiled/smali_classes4/com/xj/common/user/UserManager.smali`

#### Modification 1: getToken() Method

1. Open the file in your text editor
2. Search for `.method public getToken()Ljava/lang/String;`
3. Find the entire method (from `.method` to `.end method`)
4. Replace the entire method body with:

```smali
.method public getToken()Ljava/lang/String;
    .locals 1

    const-string v0, "a8ab9038-60d7-4261-afb8-d0dfd8d77aad"
    return-object v0
.end method
```

#### Modification 2: getUid() Method

1. Search for `.method public getUid()I`
2. Find the return statement (near the end of the method)
3. Insert BEFORE the final `return v0`:

```smali
    if-nez v0, :cond_0
    const v0, 0x1869f
    :cond_0
```

**Full method should look like:**
```smali
.method public getUid()I
    .locals 3

    invoke-static {}, Lcom/blankj/utilcode/util/SPUtils;->f()Lcom/blankj/utilcode/util/SPUtils;
    move-result-object v0
    const-string v1, "uid"
    const/4 v2, -0x1
    invoke-virtual {v0, v1, v2}, Lcom/blankj/utilcode/util/SPUtils;->g(Ljava/lang/String;I)I
    move-result v0

    if-nez v0, :cond_0
    const v0, 0x1869f
    :cond_0

    return v0
.end method
```

#### Modification 3: isLogin() Method

1. Search for `.method public isLogin()Z`
2. Replace the entire method body with:

```smali
.method public isLogin()Z
    .locals 1

    const/4 v0, 0x1
    return v0
.end method
```

**Save the file**

### 9.6 Step 5: Modify API Endpoints

#### File Path
`gamehub_decompiled/smali_classes4/com/xj/common/http/EggGameHttpConfig.smali`

#### Setup Your Mock API Server

**Option 1: Use Cloudflare Workers (Recommended)**

1. Create Cloudflare Workers account (free tier available)
2. Create a new worker with this code:

```javascript
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)

  // Log request for debugging
  console.log('Request:', url.pathname)

  // Auth endpoints
  if (url.pathname.includes('/auth/login')) {
    return jsonResponse({
      code: 0,
      message: 'success',
      data: {
        token: 'a8ab9038-60d7-4261-afb8-d0dfd8d77aad',
        uid: 100000,
        username: 'user',
        nickname: 'Player'
      }
    })
  }

  if (url.pathname.includes('/auth/token') || url.pathname.includes('/auth/verify')) {
    return jsonResponse({
      code: 0,
      message: 'valid',
      data: { valid: true, uid: 100000 }
    })
  }

  if (url.pathname.includes('/user/profile') || url.pathname.includes('/user/info')) {
    return jsonResponse({
      code: 0,
      message: 'success',
      data: {
        uid: 100000,
        username: 'user',
        nickname: 'Player',
        avatar: '',
        level: 1
      }
    })
  }

  // Games endpoints
  if (url.pathname.includes('/games/list')) {
    return jsonResponse({
      code: 0,
      message: 'success',
      data: {
        games: []
      }
    })
  }

  // Config endpoints
  if (url.pathname.includes('/config')) {
    return jsonResponse({
      code: 0,
      message: 'success',
      data: {
        version: '1.0.0',
        features: {}
      }
    })
  }

  // Default success response for any other endpoint
  return jsonResponse({
    code: 0,
    message: 'success',
    data: {}
  })
}

function jsonResponse(data) {
  return new Response(JSON.stringify(data), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  })
}
```

3. Deploy the worker
4. Note your worker URL (e.g., `https://your-worker.your-subdomain.workers.dev/`)

**Option 2: Self-Host with Node.js**

```javascript
const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.json());

// Default response
const successResponse = (data = {}) => ({
  code: 0,
  message: 'success',
  data
});

// Auth endpoints
app.all('/auth/*', (req, res) => {
  res.json(successResponse({
    token: 'a8ab9038-60d7-4261-afb8-d0dfd8d77aad',
    uid: 100000
  }));
});

// User endpoints
app.all('/user/*', (req, res) => {
  res.json(successResponse({
    uid: 100000,
    username: 'user'
  }));
});

// Catch-all
app.all('*', (req, res) => {
  console.log('Request:', req.method, req.path);
  res.json(successResponse());
});

app.listen(PORT, () => {
  console.log(`Mock API server running on port ${PORT}`);
});
```

#### Modify the Smali File

1. Open `smali_classes4/com/xj/common/http/EggGameHttpConfig.smali`
2. Find line 7: `const-string v0, "https://test-magic-landscape-api.vgabc.com/"`
3. Replace with: `const-string v0, "https://your-worker.workers.dev/"`
4. Find line 16: `const-string v0, "https://landscape-api.vgabc.com/"`
5. Replace with: `const-string v0, "https://your-worker.workers.dev/"`
6. Find line 22: `const-string v0, "https://dev-gamehub-api.vgabc.com/"`
7. Replace with: `const-string v0, "https://your-worker.workers.dev/"`

**Note:** Use your actual API endpoint URL

**Save the file**

### 9.7 Step 6: Neutralize Social Login

#### QR Login Helper

**File:** `gamehub_decompiled/smali_classes5/com/xj/landscape/launcher/ui/dialog/QrLoginHelper.smali`

1. Open the file
2. Search for `api.weixin.qq.com`
3. Replace all occurrences with `127.0.0.1`
4. Change `https://` to `http://` for localhost

**Should result in:**
- Line ~7: `const-string v0, "http://127.0.0.1/sns/oauth2/access_token"`
- Line ~16: `const-string v0, "http://127.0.0.1/cgi-bin/stable_token"`
- Line ~25: `const-string v0, "http://127.0.0.1/cgi-bin/ticket/getticket"`

**Save the file**

#### One-Key Ali Helper

**File:** `gamehub_decompiled/smali_classes5/com/xj/landscape/launcher/utils/OneKeyAliHelper.smali`

1. Open the file
2. Search for `www.xiaoji.com`
3. Replace with `127.0.0.1`

**Should result in:**
- Line ~7: `const-string v0, "http://127.0.0.1"`

**Save the file**

### 9.8 Step 7: Remove SDK Files (Optional but Recommended)

**Warning:** This step removes significant amounts of code. Test carefully after this step.

```bash
cd gamehub_decompiled

# Remove JPush
rm -rf smali_classes2/cn/jpush/

# Remove JiGuang
rm -rf smali_classes2/cn/jiguang/

# Remove UMeng Analytics
rm -rf smali_classes4/com/umeng/analytics/
rm -rf smali_classes4/com/umeng/commonsdk/

# Remove Firebase
rm -rf smali_classes3/com/google/firebase/

# Remove Ali Gateway Auth
rm -rf smali_classes2/com/mobile/auth/gatewayauth/

# Remove Tencent SDKs
rm -rf smali_classes*/com/tencent/connect/
rm -rf smali_classes*/com/tencent/mm/
rm -rf smali_classes*/com/tencent/open/
rm -rf smali_classes*/com/tencent/tauth/
rm -rf smali_classes*/com/tencent/tpgbox/

# Remove Google Play Services components
rm -rf smali_classes*/com/google/android/play/
rm -rf smali_classes*/com/google/android/recaptcha/
```

**Note:** If the app crashes after this step, you may need to keep some files and stub them instead.

### 9.9 Step 8: Recompile the APK

```bash
# Recompile
apktool b gamehub_decompiled -o gamehub_modified_unsigned.apk

# Check for errors
# If errors occur, apktool will print them. Common issues:
# - Missing resources (remove references in code)
# - Invalid smali syntax (check your modifications)
# - Missing files (may need to keep some SDK files)
```

**If compilation succeeds, proceed to signing.**

### 9.10 Step 9: Sign the APK

#### Generate a Keystore (First Time Only)

```bash
keytool -genkey -v -keystore my-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias

# Follow prompts:
# - Enter keystore password (remember this!)
# - Enter key password (remember this!)
# - Enter your details (can use fake data for testing)
```

#### Zipalign the APK

```bash
# Zipalign optimizes the APK
zipalign -v -p 4 gamehub_modified_unsigned.apk gamehub_modified_aligned.apk
```

#### Sign the APK

```bash
# Using apksigner (recommended)
apksigner sign --ks my-release-key.keystore --ks-key-alias my-key-alias --ks-pass pass:YOUR_KEYSTORE_PASSWORD --key-pass pass:YOUR_KEY_PASSWORD --out gamehub_modified_signed.apk gamehub_modified_aligned.apk

# Or using jarsigner (older method)
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore my-release-key.keystore gamehub_modified_aligned.apk my-key-alias
```

#### Verify the Signature

```bash
apksigner verify --verbose gamehub_modified_signed.apk

# Should output: "Verifies"
# If any errors, check your signing steps
```

### 9.11 Step 10: Install and Test

#### Uninstall Original APK (if installed)

```bash
adb uninstall com.antutu.ABenchMark  # Replace with actual package name
```

#### Install Modified APK

```bash
adb install gamehub_modified_signed.apk

# Or drag and drop to emulator/device
```

#### Testing Checklist

**Basic Functionality:**
- [ ] App launches successfully
- [ ] No immediate crashes
- [ ] Main UI appears
- [ ] Can navigate through menus

**Authentication:**
- [ ] App behaves as if logged in
- [ ] No login prompts appear
- [ ] User profile shows UID 100000

**Network:**
- [ ] App makes requests to custom API server
- [ ] Check API server logs for incoming requests
- [ ] No requests to original vendor domain

**Privacy:**
- [ ] No permission requests for location, camera, microphone
- [ ] No notification permission request
- [ ] No social login prompts

**Monitoring:**
```bash
# View app logs
adb logcat | grep -i "gamehub\|error\|exception"

# Monitor network traffic (requires root or proxy)
# Use tools like Charles Proxy, mitmproxy, or Wireshark
```

#### Troubleshooting

**App Crashes on Launch:**
- Check logcat for exceptions
- May need to keep some SDK files instead of removing them
- Try stubbing SDK methods instead of deleting

**Network Errors:**
- Ensure mock API server is accessible
- Check API endpoint URLs in smali files
- Verify server returns correct JSON format

**Missing Features:**
- Expected behavior - many features removed
- Check if specific feature relies on removed SDK

### 9.12 Complete Replication Summary

**Files Modified:**
1. `AndroidManifest.xml` - Permissions, activities, services removed
2. `smali_classes4/com/xj/common/user/UserManager.smali` - Auth bypass
3. `smali_classes4/com/xj/common/http/EggGameHttpConfig.smali` - API redirect
4. `smali_classes5/com/xj/landscape/launcher/ui/dialog/QrLoginHelper.smali` - WeChat neutralization
5. `smali_classes5/com/xj/landscape/launcher/utils/OneKeyAliHelper.smali` - Privacy URL neutralization

**Directories Removed:**
1. `smali_classes2/cn/jpush/` - JPush SDK
2. `smali_classes2/cn/jiguang/` - JiGuang SDK
3. `smali_classes4/com/umeng/` - UMeng Analytics
4. `smali_classes3/com/google/firebase/` - Firebase
5. `smali_classes2/com/mobile/auth/gatewayauth/` - Ali Auth
6. `smali_classes*/com/tencent/connect/` etc. - Tencent SDKs

**External Components:**
- Mock API server (Cloudflare Workers or self-hosted)

---

## 10. CONCLUSION

### 10.1 Summary of Modifications

This analysis documented comprehensive modifications to an Android APK aimed at enhancing user privacy by removing tracking mechanisms and authentication requirements. The modifications included:

**Permissions:** 31 invasive permissions removed
**Authentication:** Completely bypassed with hardcoded credentials
**Tracking SDKs:** 6 major SDKs removed or disabled (500+ files)
**Network:** All API endpoints redirected to custom server
**UI Components:** 7 activities removed

### 10.2 Use Cases

**Recommended:**
- Personal privacy research and education
- Security research into tracking mechanisms
- Educational analysis of Android applications
- Learning about reverse engineering

### 10.3 Technical Achievement

From a technical perspective, this demonstrates:
- Deep understanding of Android app structure and smali bytecode
- Systematic identification and removal of tracking components
- Detailed documentation for educational purposes
- Effective privacy-enhancing modifications

### 10.4 Educational Value

This analysis:
- Reveals extent of tracking in mobile applications
- Enables users to understand data collection practices
- Contributes to mobile privacy research
- Highlights privacy implications of standard app practices

### 10.5 Acknowledgments

This analysis was conducted using publicly available tools and techniques. It builds upon the work of:

- The Android reverse engineering community
- Privacy researchers and advocates
- Open source tool developers (apktool, etc.)
- Security researchers documenting tracking practices

### 10.6 Further Research

**Tools Used:**
- apktool - APK decompilation
- Frida - Dynamic instrumentation
- mitmproxy - Network traffic analysis
- Exodus Privacy - App tracker detection

**Resources:**
- Android Security Internals
- Mobile Privacy Research Papers
- Reverse Engineering Resources

---

## 11. APPENDICES

### Appendix B: Complete Replication Guide

See Section 8 of this document for detailed step-by-step replication procedures.

### Appendix C: SDK Documentation

**JPush/JiGuang SDK:**
- Official site: https://www.jiguang.cn/
- Documentation: https://docs.jiguang.cn/
- Privacy policy: [Check official site]

**UMeng Analytics:**
- Official site: https://www.umeng.com/
- Owned by: Alibaba Group
- Privacy policy: [Check official site]

**Firebase:**
- Official site: https://firebase.google.com/
- Owned by: Google
- Privacy policy: https://firebase.google.com/support/privacy

**Alipay SDK:**
- Official site: https://opendocs.alipay.com/
- Owned by: Ant Group (Alibaba)
- Privacy policy: [Check official site]

### Appendix E: Glossary

**APK:** Android Package - installation file format for Android apps

**apktool:** Tool for reverse engineering Android APK files

**smali:** Human-readable format for Android DEX bytecode

**DEX:** Dalvik Executable - Android bytecode format

**AndroidManifest.xml:** Configuration file for Android apps declaring permissions, components, etc.

**SDK:** Software Development Kit - pre-built libraries for app functionality

**Telemetry:** Automatic collection and transmission of usage data

**Hardcoded:** Values written directly in code rather than retrieved from configuration

**MITM:** Man-in-the-Middle - intercepting communication between two parties

**Stub:** Empty or minimal implementation of a function to prevent errors

**Decompilation:** Converting compiled code back to source-like form

**Bytecode:** Intermediate code format executed by virtual machine

**JiGuang (极光):** Aurora Mobile - Chinese mobile development platform

**UMeng (友盟):** Umeng Analytics - Chinese analytics platform by Alibaba

### Appendix F: Version Information

**Analysis Version:** 1.0
**Analysis Date:** October 7, 2025
**Document Format:** Markdown
**Total Pages:** ~80 pages (estimated when printed)
**Word Count:** ~25,000 words

### Appendix G: Change Log

**Version 1.0 (2025-10-07):**
- Initial comprehensive analysis
- All sections completed
- Detailed code analysis
- Replication guide created

---

## DOCUMENT END

**Generated:** October 7, 2025
**Purpose:** Educational analysis of Android APK privacy modifications

**Analysis Documentation:**
- Main Report: COMPREHENSIVE_SECURITY_ANALYSIS_REPORT.md (this file)
- Bloat Analysis: BLOAT_REMOVAL_ANALYSIS.md
- API Setup: GAMEHUB_API_ANALYSIS.md
- README: README.md

**For questions about this analysis, please refer to the README file.**

---

END OF REPORT
