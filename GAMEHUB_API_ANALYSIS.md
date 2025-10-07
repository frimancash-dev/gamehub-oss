# GameHub API Architecture Analysis

**Date:** October 7, 2025
**Analysis of:** Privacy-respecting API infrastructure for GameHub Android app

---

## Overview

The GameHub API consists of two interconnected components working together to provide a privacy-respecting alternative to the original Chinese API infrastructure:

1. **Cloudflare Worker** (Edge proxy) - `gamehub-worker/`
2. **GitHub Static API** (Data repository) - `gamehub_api/`

---

## Component 1: Cloudflare Worker (Edge Proxy)

### Location
- **Local path:** `/gamehub-worker/`
- **Deployed URL:** `https://gamehub-api.secureflex.workers.dev`
- **Main file:** `src/index.ts` (287 lines)

### Purpose
Acts as an intelligent routing layer that:
- Intercepts ALL API requests from the modified GameHub APK
- Routes requests to appropriate backends (GitHub static files or Chinese server)
- Sanitizes device fingerprints to protect user privacy
- Hides user IP addresses when proxying to Chinese servers
- Handles CORS for cross-origin requests
- Implements caching for performance

### File Structure
```
gamehub-worker/
├── src/
│   └── index.ts              # Main worker code (287 lines)
├── wrangler.jsonc            # Cloudflare deployment config
├── package.json              # NPM dependencies & scripts
├── tsconfig.json             # TypeScript configuration
├── node_modules/             # Dependencies
├── public/                   # Static assets
└── test/                     # Unit tests
```

### Key Configuration (wrangler.jsonc)
```json
{
  "name": "gamehub-api",
  "main": "src/index.ts",
  "compatibility_date": "2025-10-03",
  "compatibility_flags": ["global_fetch_strictly_public"],
  "assets": { "directory": "./public" },
  "observability": { "enabled": true }
}
```

### Worker Code Analysis

#### Constants (Lines 8-20)
```typescript
const GITHUB_BASE = 'https://raw.githubusercontent.com/gamehublite/gamehub_api/main';
const WORKER_URL = 'https://gamehub-api.secureflex.workers.dev';

const TYPE_TO_MANIFEST: Record<number, string> = {
  1: '/components/box64_manifest',     // Box64 emulator versions
  2: '/components/drivers_manifest',   // GPU drivers (Mali, Adreno, etc.)
  3: '/components/dxvk_manifest',      // DirectX to Vulkan translation
  4: '/components/vkd3d_manifest',     // Direct3D 12 to Vulkan
  5: '/components/games_manifest',     // Pre-configured game profiles
  6: '/components/libraries_manifest', // Windows libraries for Wine
  7: '/components/steam_manifest',     // Steam integration files
};
```

#### Endpoint Handlers (10 total)

**1. Component List** - `POST /simulator/v2/getComponentList` (Lines 201-256)
- **Purpose:** Return paginated list of downloadable components
- **Data source:** GitHub static files
- **Processing:**
  - Maps type number (1-7) to manifest file
  - Fetches from GitHub
  - Transforms "components" key to "list" (app compatibility)
  - Handles pagination (page, page_size parameters)
- **Privacy:** No user data sent anywhere

**2. Game Detail** - `POST /card/getGameDetail` (Lines 46-62)
- **Purpose:** Fetch game metadata (title, description, images)
- **Data source:** Chinese server (landscape-api.vgabc.com)
- **Processing:** Proxy request with original headers (for signature)
- **Privacy:** User IP HIDDEN (Chinese server sees Cloudflare IP)

**3. GPU Configuration** - `POST /simulator/executeScript` (Lines 77-112)
- **Purpose:** Get optimal game settings based on GPU
- **Data source:** Chinese server
- **Processing:**
  - SANITIZES request body
  - Strips device model, precise GPU info, driver version
  - Only sends GPU vendor (Mali/Adreno/Qualcomm/etc.)
  - Replaces real data with generic values
- **Privacy:** Device fingerprint STRIPPED

**Sanitization example:**
```typescript
// BEFORE (from app):
{
  gpu_vendor: "Qualcomm",
  gpu_device_name: "Adreno 660",
  gpu_version: 512,
  gpu_system_driver_version: "512.0.0",
  // ... (identifies specific device)
}

// AFTER (sent to server):
{
  gpu_vendor: "Qualcomm",              // Only field needed
  gpu_device_name: "Generic Device",   // Generic
  gpu_version: 0,                      // Generic
  gpu_system_driver_version: 0,        // Generic
  clientparams: "5.1.0|0|en|Generic|1920*1080|..."
}
```

**4. Base Info** - `POST /base/getBaseInfo` (Lines 115-130)
- **Data source:** GitHub static
- **Returns:** App configuration (cloud_game_switch, guide images)

**5. Steam Hosts** - `GET /game/getSteamHost` (Lines 170-186)
- **Data source:** GitHub static
- **Returns:** Plain text hosts file with optimized Steam CDN IPs

**6. News List** - `POST /card/getNewsList` (Lines 65-74)
- **Data source:** Worker-generated
- **Returns:** Empty array (promotional content removed)

**7. Game Icons** - `POST /card/getGameIcon` (Lines 189-198)
- **Data source:** Worker-generated
- **Returns:** Empty array (UI-only, not critical)

**8. Cloud Sync Timer** - `POST /cloud/game/check_user_timer` (Lines 133-148)
- **Data source:** GitHub static
- **Returns:** Empty (cloud sync feature removed)

**9. DNS IP Pool** - `POST /game/getDnsIpPool` (Lines 151-167)
- **Data source:** GitHub static
- **Returns:** Empty (allows direct Steam connections)

**10. Fallback Handler** (Lines 258-278)
- **Catches:** All unhandled endpoints
- **Data source:** GitHub static (proxy)
- **Caching:** 5 minutes (cacheTtl: 300)

#### CORS Handling (Lines 29-38)
```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

if (request.method === 'OPTIONS') {
  return new Response(null, { headers: corsHeaders });
}
```

#### Error Handling (Lines 279-284)
```typescript
catch (error) {
  return new Response(JSON.stringify({
    code: 500,
    msg: `Error: ${error.message}`
  }), {
    status: 500,
    headers: { 'Content-Type': 'application/json', ...corsHeaders }
  });
}
```

---

## Component 2: GitHub Static API (Data Repository)

### Location
- **Local path:** `/gamehub_api/`
- **GitHub repo:** `https://github.com/gamehublite/gamehub_api`
- **Raw URL:** `https://raw.githubusercontent.com/gamehublite/gamehub_api/main/`

### Purpose
Hosts static JSON files and configuration data that was previously served by Chinese servers:
- Component manifests (emulators, drivers, libraries)
- Base configuration
- Steam CDN optimization files
- Empty responses for removed features

### Directory Structure
```
gamehub_api/
├── .git/                     # Git repository
├── agreement/                # User agreement files
├── base/
│   └── getBaseInfo           # App base configuration (JSON)
├── card/                     # Game card/detail endpoints
├── cloud/
│   └── game/
│       └── check_user_timer  # Cloud sync timer (empty JSON)
├── components/               # Component download manifests
│   ├── box64_manifest        # Box64 emulator versions (11 items)
│   ├── drivers_manifest      # GPU drivers (50+ items)
│   ├── dxvk_manifest         # DirectX to Vulkan layers
│   ├── vkd3d_manifest        # Direct3D 12 to Vulkan
│   ├── games_manifest        # Pre-configured game profiles
│   ├── libraries_manifest    # Windows libraries
│   └── steam_manifest        # Steam integration files
├── devices/                  # Device compatibility info
├── email/                    # Email-related endpoints
├── ems/                      # EMS-related endpoints
├── game/
│   ├── checkLocalHandTourGame
│   ├── getDnsIpPool          # DNS pool (empty - allows real Steam)
│   ├── getGameCircleList
│   ├── getSteamHost/
│   │   └── index             # Steam CDN IPs (hosts file format)
│   └── userVideoNum
├── simulator/
│   └── v2/
│       └── getComponentList  # Generic component list
└── upgrade/                  # App update info
```

### Key Files Analysis

#### 1. base/getBaseInfo
```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "cloud_game_switch": 2,
    "guide_info_img": "https://zlyer-cdn-comps-en.bigeyes.com/...",
    "guide_storage_img": "https://zlyer-cdn-comps-en.bigeyes.com/..."
  },
  "time": "1759483449"
}
```

#### 2. components/box64_manifest (Example)
```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "type": 1,
    "type_name": "box64",
    "display_name": "Box64 Emulators",
    "total": 11,
    "components": [
      {
        "id": 327,
        "name": "Box64-0.37-b2",
        "version": "1.0.0",
        "version_code": 1,
        "download_url": "https://zlyer-cdn-comps-en.bigeyes.com/ux-landscape/pc_zst/bfb6/b3/91/bfb6b3914b8f7abb792d8acafa676861.tzst",
        "file_md5": "bfb6b3914b8f7abb792d8acafa676861",
        "file_size": "4272182",
        "file_name": "Box64-0.37-b2.tzst",
        "logo": "https://zlyer-cdn-comps-en.bigeyes.com/...",
        "is_ui": 1,
        "type": 1
      }
      // ... 10 more items
    ]
  }
}
```

**Component Types:**
- Type 1: Box64 (x86_64 emulator for ARM64)
- Type 2: Drivers (GPU-specific drivers: Mali, Adreno, PowerVR)
- Type 3: DXVK (DirectX 9/10/11 to Vulkan)
- Type 4: VKD3D (Direct3D 12 to Vulkan)
- Type 5: Games (Pre-configured Wine prefixes)
- Type 6: Libraries (Windows DLLs for Wine)
- Type 7: Steam (Steam client integration)

#### 3. game/getSteamHost/index (Plain text)
```
#steam Start
23.47.27.74         steamcommunity.com
104.94.121.98       www.steamcommunity.com
23.45.149.185       store.steampowered.com
23.47.27.74         api.steampowered.com
23.53.35.201        store.akamai.steamstatic.com
#steam End
# Last Update Time : 2025-06-30 09:55:04
```

---

## How Both Components Work Together

### Request Flow Diagram
```
[GameHub APK]
      |
      | All API requests to: gamehub-api.secureflex.workers.dev
      v
[Cloudflare Worker] (Routes based on endpoint)
      |
      +-- Static data (manifests, config) --> [GitHub Raw API]
      |                                             |
      |                                             v
      |                                       Returns JSON
      |
      +-- Game metadata, GPU configs -------> [Chinese Server]
      |   (User IP hidden, fingerprint sanitized)
      |                                             |
      |                                             v
      |                                       Returns JSON
      |
      +-- Empty responses (news, icons) ----> Worker generates
      |
      v
Returns to app
```

### Example: Component Download Request

**1. App sends request:**
```http
POST https://gamehub-api.secureflex.workers.dev/simulator/v2/getComponentList
Content-Type: application/json

{
  "type": 1,
  "page": 1,
  "page_size": 10
}
```

**2. Worker receives and routes:**
```typescript
// Worker maps type 1 to box64_manifest
const manifestUrl = 'https://raw.githubusercontent.com/gamehublite/gamehub_api/main/components/box64_manifest';
const response = await fetch(manifestUrl);
```

**3. GitHub returns manifest:**
```json
{
  "code": 200,
  "data": {
    "components": [ /* 11 Box64 versions */ ]
  }
}
```

**4. Worker transforms and paginates:**
```typescript
// Rename "components" to "list"
manifestData.data.list = manifestData.data.components;
delete manifestData.data.components;

// Paginate (page 1, size 10)
const paginatedItems = allItems.slice(0, 10);
manifestData.data.list = paginatedItems;
manifestData.data.page = 1;
manifestData.data.pageSize = 10;
manifestData.data.total = 11;
```

**5. App receives:**
```json
{
  "code": 200,
  "data": {
    "list": [ /* 10 items */ ],
    "page": 1,
    "pageSize": 10,
    "total": 11
  }
}
```

**6. App downloads component directly:**
```
https://zlyer-cdn-comps-en.bigeyes.com/ux-landscape/pc_zst/bfb6/b3/91/bfb6b3914b8f7abb792d8acafa676861.tzst
```
- No worker involvement (direct CDN download)
- Worker never sees download traffic
- User IP not logged by worker

---

## Privacy Features

### 1. IP Address Protection
```
Original flow:
User (IP: 123.45.67.89) --> Chinese Server
Server logs: 123.45.67.89 [TRACKED]

Modified flow:
User (IP: 123.45.67.89) --> Cloudflare Worker --> Chinese Server
Server logs: Cloudflare IP (104.21.x.x) [USER IP HIDDEN]
```

### 2. Device Fingerprint Sanitization
- Device model: "Samsung Galaxy S21" --> "Generic Device"
- GPU model: "Adreno 660" --> "0"
- Driver version: "512.0.0" --> "0"
- Only GPU vendor sent: "Qualcomm" (needed for configuration)

### 3. No Download Proxying
```
BAD approach (Worker sees all downloads):
User --> Worker --> CDN --> Worker --> User

GOOD approach (Worker only provides URLs):
User --> Worker (gets URL) --> User downloads directly from CDN
```

### 4. Caching for Performance
- GitHub responses cached for 5 minutes
- Reduces GitHub API calls
- Faster response times for users

---

## Deployment

### Cloudflare Worker
```bash
cd gamehub-api
npm install
npm run deploy
```

Output:
```
Deployed gamehub-api triggers
  https://gamehub-api.secureflex.workers.dev
```

### GitHub Static API
```bash
cd gamehub_api

# Make changes to manifest files
vim components/box64_manifest

# Commit and push
git add .
git commit -m "Update Box64 versions"
git push origin main
```

Changes propagate:
- GitHub: Immediate (< 10 seconds)
- Cloudflare cache: 5 minutes
- App receives: Next request after cache expiry

---

## Request Statistics

### Proxied Requests (User IP Hidden)
1. `POST /card/getGameDetail` - Game metadata
2. `POST /simulator/executeScript` - GPU configs (sanitized)

### GitHub Static (No Privacy Risk)
1. `POST /simulator/v2/getComponentList` - Component downloads
2. `POST /base/getBaseInfo` - Base config
3. `GET /game/getSteamHost` - Steam CDN IPs
4. `POST /cloud/game/check_user_timer` - Cloud sync (empty)
5. `POST /game/getDnsIpPool` - DNS pool (empty)
6. Fallback handler - All other endpoints

### Worker Generated (No External Request)
1. `POST /card/getNewsList` - News (empty)
2. `POST /card/getGameIcon` - Icons (empty)

---

## Summary

**Before modification:**
- All requests to Chinese servers
- User IP logged
- Full device fingerprint sent
- Analytics tracking active

**After modification:**
- Requests to Cloudflare Worker (privacy-respecting)
- User IP HIDDEN (Cloudflare IP sent instead)
- Device fingerprint SANITIZED
- Analytics COMPLETELY REMOVED
- CDN downloads DIRECT (no proxy)
- GitHub static data (open source, auditable)

**End of Analysis**
