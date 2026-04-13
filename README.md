# AoB — Anthony Digital Twin Pipeline

Automated video generation pipeline for Alchemy of Breath using HeyGen's AI avatar platform.

## Architecture

```
Google Drive (footage/output) → GitHub Actions (orchestration) → HeyGen API (rendering)
```

- **No servers** — GitHub Actions runs everything on-demand or via cron
- **No infrastructure** — Google Drive for storage, HeyGen for compute
- **Claude Code** — setup, scripting, and configuration

## Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `create-video.yml` | Manual (`workflow_dispatch`) | Generate a video from a text prompt |
| `translate-video.yml` | Manual (`workflow_dispatch`) | Translate a video into multiple languages |
| `blog-to-video.yml` | Push to `content/blog/` | Auto-convert blog posts to avatar videos |
| `weekly-update.yml` | Cron (Monday 8am UTC) | Weekly community update video |

## Setup

### 1. GitHub Secrets

| Secret | Source |
|--------|--------|
| `HEYGEN_API_KEY` | [HeyGen Settings → API](https://app.heygen.com/settings?nav=API) |
| `ANTHONY_LOOK_ID` | From avatar creation (e.g. `look_XXXX`) |
| `ANTHONY_VOICE_ID` | From voice clone setup |
| `ANTHROPIC_API_KEY` | [Anthropic Console](https://console.anthropic.com/) |
| `GOOGLE_SERVICE_ACCOUNT` | Google Cloud service account JSON key |
| `DRIVE_OUTPUT_FOLDER_ID` | Google Drive folder ID for generated videos |

### 2. Avatar Creation

1. Audit existing footage against the scorecard in this README
2. Create Digital Twin via HeyGen web UI (or Avatar V for rapid prototype)
3. Record and upload consent video
4. Note the `LOOK_ID` and `VOICE_ID` — add as GitHub Secrets

### 3. Google Drive Structure

```
AOB Digital Twin/
├── 01-Training-Footage/
│   ├── selected/
│   └── consent/
├── 02-Generated-Videos/
│   ├── english/
│   ├── spanish/
│   ├── german/
│   ├── portuguese/
│   ├── french/
│   └── italian/
├── 03-SRT-Reviews/
├── 04-Blog-Posts/
└── 05-Weekly-Updates/
```

## Footage Audit Scorecard

For each candidate clip, score against HeyGen's requirements:

| Criterion | Requirement | Score |
|-----------|-------------|-------|
| Continuous shot | No cuts or edits | /1 |
| Duration | 2+ minutes of speech | /1 |
| Resolution | 1080p or higher | /1 |
| Framing | Head + upper body, stable | /1 |
| Eye contact | Looking at camera lens | /1 |
| Lighting | Even, no harsh shadows | /1 |
| Background | Simple, static | /1 |
| Audio | Clear, no echo/noise | /1 |
| Stability | Tripod, no shake | /1 |
| Clothing | No logos/busy patterns | /1 |
| Gestures | Natural, hands below chest | /1 |
| Expression | Not monotone | /1 |

**Minimum viable:** 8/12 (no fails on continuous, duration, eye contact)

## Cost Estimate

| Item | Cost |
|------|------|
| HeyGen Creator plan | $29/mo |
| API credits (~70) | ~$70/mo |
| GitHub Actions | Free tier |
| Google Drive | Existing |
| **Total** | **~$100/mo** |
