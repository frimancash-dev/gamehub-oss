# GameHub APK Security Analysis

## What's This?

I analyzed the GameHub Android app and ripped out all the tracking, bloat, and authentication. This directory has all my notes and findings.

---

## Where to Start

**Want the quick version?**
→ Read `COMPREHENSIVE_SECURITY_ANALYSIS_REPORT.md` - Sections 1-3

**Want all the technical details?**
→ Read the full `COMPREHENSIVE_SECURITY_ANALYSIS_REPORT.md`

**Want to do it yourself?**
→ Check the replication procedures in the main report (Section 8)

---

## What's In Here

### Main Reports

**COMPREHENSIVE_SECURITY_ANALYSIS_REPORT.md**
- My complete analysis of everything I changed
- 13 sections covering permissions, authentication, bloat removal, etc.
- Includes the 115MB → 55MB size reduction breakdown
- Has exact code snippets so you can replicate it

**GAMEHUB_API_ANALYSIS.md**
- How I set up my custom API server
- Instructions for deploying to Cloudflare Workers
- Mock responses for the hardcoded auth

**BLOAT_REMOVAL_ANALYSIS.md**
- Deep dive on the 60MB I removed
- Every native library explained with sizes
- Why I deleted each asset file
- Performance benchmarks

---

## What I Found

### Privacy Wins
- Removed 31 invasive permissions (location, mic, camera, contacts, etc.)
- Deleted 6 tracking SDKs (500+ files of spyware)
- Zero telemetry sent to the vendor now
- No more location tracking
- Can't access mic/camera anymore
- Device fingerprinting is gone

### The Authentication Hack
- Completely bypassed login with hardcoded credentials
- Token: `same token (everyone shares this)
- User ID: `100000` (also shared)
- All API calls go to MY server now (cloudflare workers)
- Social login (WeChat, QQ, Alipay) disabled

### By The Numbers
- 81 files I manually edited
- 3,389 files deleted (tracking SDKs mostly)
- 2,872 files added during recompilation
- ~70MB of analysis files
- About 25,000 words of documentation

---

## Document Structure

### COMPREHENSIVE_SECURITY_ANALYSIS_REPORT.md Sections

1. **Introduction** - Background and scope
2. **Methodology** - Analysis techniques and tools
3. **Permission Removal Analysis** - All 31 permissions documented
4. **Authentication Bypass Analysis** - Hardcoded credentials and login bypass
5. **Telemetry and Tracking Removal** - 6 SDKs analyzed
6. **Network Configuration Changes** - API redirection and MITM
7. **UI/UX Modifications** - Removed activities and dialogs
8. **Replication Procedures** - Complete step-by-step guide
9. **Security Implications** - Risk assessment and mitigation
10. **Conclusion** - Summary and recommendations
11. **Appendices** - Reference materials and glossary

---

## How This Was Done

### Phase 1: Discovery
1. Decompiled APKs using apktool
2. Doucment thoroughly
3. Identified 81 modified files
4. Catalogued 3,389 deletions and 2,872 additions

### Phase 2: Analysis
1. Categorized changes by type
2. Analyzed each modification for purpose
3. Documented security/privacy implications
4. Created detailed code-level analysis

### Phase 3: Documentation
1. Wrote comprehensive analysis report
2. Created step-by-step replication guide
3. Documented all code changes with snippets

---

## Why These Changes Were Made

### Primary Objectives
1. **Privacy Enhancement** - Remove all tracking and telemetry
2. **Authentication Bypass** - Eliminate login requirements
3. **Network Control** - Redirect all traffic to custom server
4. **Permission Minimization** - Remove unnecessary permissions

### Specific Rationales

**Permission Removal:**
- Prevent location surveillance
- Block audio/video recording
- Stop device fingerprinting
- Eliminate ad tracking

**Telemetry Removal:**
- JPush - Push notification tracking
- JiGuang - Core analytics
- Firebase - Google analytics and auth
- UMeng - Alibaba analytics
- Alipay - Payment tracking

**Authentication Bypass:**
- Remove login barriers
- Prevent social login tracking
- Block carrier authentication data collection
- Enable offline usage

**Network Redirection:**
- Intercept all API calls
- Mock server responses
- Prevent vendor tracking
- Full control over app-server communication

---

## How to Replicate

### Prerequisites
- apktool (decompilation)
- Text editor
- Java JDK 8+
- Android SDK (signing tools)

### Quick Steps
1. Decompile APK with apktool
2. Modify AndroidManifest.xml (remove permissions and components)
3. Modify UserManager.smali (hardcode credentials)
4. Modify EggGameHttpConfig.smali (redirect API)
5. Modify QrLoginHelper.smali and OneKeyAliHelper.smali (neutralize social login)
6. Remove SDK directories (optional)
7. Recompile with apktool
8. Sign with apksigner
9. Install and test

### Detailed Instructions
See main report

---

## Security Implications

### The Good
- Your location isn't being tracked anymore
- No mic/camera surveillance
- They can't fingerprint your device
- No behavioral analytics tracking what you do
- Zero data going to the vendor or Chinese servers

### The Bad
- My custom API server sees all your traffic (you have to trust me) **or simply host it yourself** using the repos listed above
- You won't get updates from the vendor
- Some features might break

**Bottom line:** Only use this for personal privacy research. You can self-host all workers for complete privacy. Don't share the modded APK.

---

## Files in This Repository

```
├── README.md (this file)
├── COMPREHENSIVE_SECURITY_ANALYSIS_REPORT.md (main report)
├── GAMEHUB_API_ANALYSIS.md (API mock server guide)
└── BLOAT_REMOVAL_ANALYSIS.md (detailed bloat analysis)
```

---

## Required Repositories

This project requires the following Cloudflare Worker repositories for full functionality:

1. **[gamehub-worker](https://github.com/gamehublite/gamehub-worker)** - Main API proxy worker
   - Handles all GameHub API requests
   - Token replacement and signature regeneration
   - Privacy features (IP protection, fingerprint sanitization)

2. **[gamehub_api](https://github.com/gamehublite/gamehub_api)** - Static API resources
   - Component manifests (Wine, Proton, DXVK, VKD3D)
   - Game configurations and profiles
   - Served via GitHub raw URLs

3. **[gamehub-news](https://github.com/gamehublite/gamehub-news)** - News aggregator worker
   - Aggregates gaming news from RSS feeds
   - Tracks GitHub releases for emulation projects
   - Custom HTML styling for mobile

4. **[gamehub-login-token-grabber](https://github.com/gamehublite/gamehub-login-token-grabber)** - Token refresher worker
   - Automated token refresh every 4 hours
   - OTP-based authentication via Mail.tm
   - Stores fresh tokens in KV storage

**Note:** You can self-host your own instances of the whole GameHub app if you want to. Right now I am using a free Cloudflare Worker I created. Please don't misuse the project. The size of the APK is cut down to **47MB from 115MB**.

---

## Analysis Metadata

**Analysis Date:** October 7, 2025
**Version:** 1.0
**Total Analysis Size:** ~70MB
**Documentation:** ~25,000 words
**Original APK Size:** 115MB
**Modified APK Size:** 47MB (59% reduction)
**Modified APK:** gamehub_lite.apk

---

## Next Steps

### For Learning
1. Read the comprehensive report
2. Understand the tracking mechanisms
3. Learn about privacy-preserving techniques
4. Study the code modifications

### For Replication
1. Follow the replication guide in the main report
2. Set up tools (apktool, JDK, Android SDK)
3. Deploy Cloudflare Workers from the required repositories (see above)
   - Fork and deploy [gamehub-worker](https://github.com/gamehublite/gamehub-worker)
   - Fork and deploy [gamehub-news](https://github.com/gamehublite/gamehub-news)
   - Fork and deploy [gamehub-login-token-grabber](https://github.com/gamehublite/gamehub-login-token-grabber)
   - Use [gamehub_api](https://github.com/gamehublite/gamehub_api) static files
4. Update APK to point to your worker URLs
5. Follow step-by-step procedures
6. Test thoroughly

### For Research
1. Analyze the SDK removal techniques
2. Study network traffic patterns
3. Test app functionality
4. Document your findings

---

## Contact & Support

This is an educational analysis provided as-is. For questions about:
- **Android reverse engineering:** See apktool documentation
- **Technical issues:** Refer to the replication procedures in the main report

---

## Acknowledgments

This analysis uses:
- apktool (open source APK decompilation tool)
- Standard Unix tools (grep, find)
- Android SDK tools (apksigner, zipalign)
- HTTP Toolkit
- VSCode

Built upon knowledge from:
- Android reverse engineering community
- Privacy research community
- Open source security tools

---

## Version History

**v1.0 (2025-10-07)**
- Initial comprehensive analysis completed
- All 12 sections documented
- Replication procedures included

---

**END OF README**

For detailed information, see: COMPREHENSIVE_SECURITY_ANALYSIS_REPORT.md
