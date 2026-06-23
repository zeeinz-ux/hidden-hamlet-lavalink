# hidden-hamlet-lavalink

Custom Lavalink server build — tuned for Discord music bots running on Render, with hardened YouTube playback and Spotify provider passthrough via lavasrc.

## 🔌 Plugins

| Plugin | Version | Source |
|---|---|---|
| `dev.lavalink.youtube:youtube-plugin` | `1.18.1` (locked) | `https://maven.lavalink.dev/releases` |
| `com.github.topi314.lavasrc:lavasrc-plugin` | `4.8.1` | `https://maven.lavalink.dev/releases` |
| `com.github.topi314.lavasearch:lavasearch-plugin` | `1.0.0` | `https://maven.lavalink.dev/releases` |

The youtube-plugin version is **deliberately pinned to `1.18.1`**, the latest stable release on the official Maven repository at the time of this audit. YouTube's signature cipher rotates aggressively, so we keep `oauth.enabled: true` mandatory to bypass bot-flagged datacenter IPs (Render).

## 🎯 YouTube Client Priority

The client list under `plugins.youtube.clients` is ordered for resilience against YouTube's bot detection. Lavalink walks the list top-to-bottom until one succeeds.

```
TV            → Primary OAuth client (uses ${YOUTUBE_REFRESH_TOKEN})
MWEB          → Lightweight mobile-web fallback, rarely flagged
WEB           → Solid fallback for search/playlist/mix
IOS           → Stable, supports OAuth, second-tier fallback
ANDROID_VR    → Tertiary fallback
TVHTML5_SIMPLY → Last-resort fallback
```

If `TV` is rejected by YouTube (typical when the OAuth token is stale or the IP is flagged), the plugin walks down the list. Adding `MWEB` and `IOS` significantly improves recoverability when `TVHTML5` variants throw `Must find sig function from script` or `Sign in to confirm you're not a bot`.

## 🔐 Required Environment Variables

| Variable | Purpose |
|---|---|
| `LAVALINK_PASSWORD` | Lavalink WS/REST server password |
| `YOUTUBE_REFRESH_TOKEN` | OAuth refresh token for the TV client (REQUIRED) |
| `SPOTIFY_CLIENT_ID` | Spotify provider client id (lavasrc) |
| `SPOTIFY_CLIENT_SECRET` | Spotify provider client secret (lavasrc) |

> ⚠️ All four must be set in Render → Environment. Do not commit any actual secret value to this repo — only the `${...}` placeholder is allowed inside `application.yml`.

## 📦 Changelog

### 2026-06-24 — YouTube resilience + Spotify placeholder fix

- **YouTube client list re-ordered and extended.** New order: `TV → MWEB → WEB → IOS → ANDROID_VR → TVHTML5_SIMPLY`. Added `MWEB` and `IOS` to the priority chain so that when `TV`/`TVHTML5_SIMPLY` are rejected by YouTube (cipher mismatch or bot-flag), playback can recover via lighter clients instead of failing every track with `All clients failed to load the item`.
- **Pinned `youtube-plugin` to `1.18.1`** (latest stable on `maven.lavalink.dev/releases`). Version is locked intentionally — no snapshot/dev-hash bumps without a fresh audit. `oauth.enabled` stays `true` and `skipInitialization: false` so the TV client always authenticates with the refresh token before serving tracks.
- **Fixed corrupted `${SPOTIFY_CLIENT_SECRET}` placeholder** in `plugins.lavasrc.spotify.clientSecret`. The previous value (`${SPOT…CRET}`) had a literal Unicode ellipsis (`U+2026`) inserted mid-name, which would have caused lavasrc to look up an undefined env var and silently skip Spotify matches. Now correctly reads `${SPOTIFY_CLIENT_SECRET}`.

### Initial

- Single-instance Lavalink server on port `8080` (Render-aligned).
- YouTube handled by `youtube-plugin`, Spotify/SoundCloud handled by `lavasrc`.
- Debug logging for `dev.lavalink.youtube.*` and `com.sedmelluq.discord.lavaplayer`.
