# AoB — Digital Twin Pipeline

Automated video generation pipeline using HeyGen's AI avatar platform.

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
| `create-twin.yml` | Manual (`workflow_dispatch`) | Create a Digital Twin from training footage |
| `create-video.yml` | Manual (`workflow_dispatch`) | Generate a video from a text prompt |
| `translate-video.yml` | Manual (`workflow_dispatch`) | Translate a video into multiple languages |
| `blog-to-video.yml` | Push to `content/blog/` | Auto-convert blog posts to avatar videos |
| `weekly-update.yml` | Cron (Monday 8am UTC) | Weekly community update video |

## Setup

### 1. GitHub Secrets

| Secret | Description |
|--------|-------------|
| `HEYGEN_API_KEY` | [HeyGen Settings → API](https://app.heygen.com/settings?nav=API) |
| `AVATAR_LOOK_ID` | From avatar creation (e.g. `look_XXXX`) |
| `AVATAR_VOICE_ID` | From voice clone setup |
| `AVATAR_NAME` | Presenter's full name (used in prompts) |
| `BRAND_NAME` | Brand/organization name (used in prompts) |
| `BRAND_WEBSITE` | Brand website URL (used in CTAs) |
| `ANTHROPIC_API_KEY` | [Anthropic Console](https://console.anthropic.com/) |
| `GOOGLE_SERVICE_ACCOUNT` | Google Cloud service account JSON key |
| `DRIVE_OUTPUT_FOLDER_ID` | Google Drive folder ID for generated videos |

### 2. Avatar Creation

1. Audit existing footage against the scorecard below
2. Run the `create-twin.yml` workflow with training footage + consent video URLs
3. Note the `LOOK_ID` and `VOICE_ID` — add as GitHub Secrets

### 3. Google Drive Structure

Set up a folder structure on Drive for input/output:

```
Digital-Twin/
├── training-footage/
│   ├── selected/
│   └── consent/
├── generated-videos/
│   ├── english/
│   └── translations/
├── srt-reviews/
└── blog-posts/
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
