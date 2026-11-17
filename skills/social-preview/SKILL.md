---
name: social-preview
license: MIT
description: >-
  Create and fix social/link-preview images and Open Graph metadata so shared links and profile avatars render correctly. Use this skill whenever the user changes a GitHub/LinkedIn/social avatar or profile picture, ships or "features" a project/portfolio/landing page, notices a LinkedIn or social link preview showing the wrong/old/cropped/decapitated image, asks to add or fix og:image / Open Graph / Twitter-card meta, wants a "share card" or 1200x630 preview image, or needs to bust a stale link-preview cache. Also use for reframing a square image so it survives BOTH a circular avatar mask and the 1.91:1 landscape link-preview center-crop. It bundles deterministic PowerShell compositing scripts, an OG/Twitter meta template, and the cache-bust + Featured re-add playbook. Reach for it even when the user does not say "Open Graph" — "my LinkedIn preview looks wrong," "the thumbnail is cut off," or "the card is blank" all mean this skill.
---

# Social / Link Preview & Open Graph

Two unglamorous problems break shared links and avatars over and over, and they are easy to misdiagnose as each other:

1. **Crop geometry.** Different surfaces crop the *same* image differently. A square avatar is masked to a **circle** on GitHub/Slack, but a **1.91:1 landscape center-strip** in a LinkedIn/Twitter *link preview*. An image composed for one gets decapitated by the other.
2. **Cache layers.** A platform caches (and often *re-hosts*) the preview it scraped. Changing the source does nothing until you invalidate the cache — and re-scraping the same URL frequently returns the cached copy anyway.

This skill encodes the fixes for both, with bundled scripts so the image work is deterministic (no eyeballing pixel math) and a meta template so pages get correct, consistent tags.

## Mental model (read this first — it prevents misdiagnosis)

- **A profile avatar is never just an avatar.** It is the upstream source for every downstream crop: GitHub circle, LinkedIn link-preview strip, Slack/Discord circle. Design it to survive *all* of them at once, not one.
- **The 1.91:1 link-preview strip keeps only the center ~52% of a square's height** and slices top + bottom. So a full-bleed or face-filling square loses the head. The fix is margin: float the subject inside the center band.
- **Three caches sit between a source image and a rendered card:** (1) the host's own image/CDN (e.g. GitHub's generated `opengraph.githubassets.com` card, whose hash changes on profile edit), (2) the *destination* page's `og:image`, and (3) the *sharing platform's* re-hosted copy (e.g. LinkedIn stores its own `media.licdn.com` derivative). A stale preview can live in any of them; identify which before "fixing" the wrong one.
- **`og:image` MUST be an absolute URL.** Relative paths break scrapers, especially under a non-root base path. Custom-domain GitHub Pages serve `public/` at the domain root, so `https://your.domain/og.png` is correct.
- **Match the site's existing voice** in meta titles and descriptions. Do not flip `og:type` to `article` just to get an author byline on a product/app page — keep `website` and use `<meta name="author">`; `article:author` belongs only on real writeups.

## Bundled scripts (Windows / PowerShell, uses .NET System.Drawing — no installs)

Run these instead of hand-writing pixel math. They are deterministic and artifact-free for flat or screenshot sources.

| Script | Purpose |
|--------|---------|
| `scripts/reframe-avatar.ps1` | Turn a square/circle-masked source into avatar variants that survive both the circle mask and the 1.91:1 strip. Produces `whole_<name>.png` (figure scaled with margin — the safe default) and optionally `crop_<name>.png` (tighter head-and-shoulders). Flattens transparent corners onto a sampled background color so nothing shows a seam. |
| `scripts/make-og-card.ps1` | Generate a `1200x630` `og.png` from any screenshot/source via cover-scale + center-crop. Drop the output in the site's `public/` (or web root). |
| `scripts/preview-strip.ps1` | **Verify before you ship.** Simulate the 1.91:1 link-preview center-strip crop on any candidate image so you can confirm the head/subject survives *before* uploading. |

Read a script's `param(...)` block for options. Typical calls:

```powershell
# Avatar: safe "whole figure with margin" variant (scale ~0.5-0.55 of the square)
powershell -File scripts/reframe-avatar.ps1 -Source C:\images\pfp.png -Mode both -Scale 0.52

# Verify it survives LinkedIn's strip BEFORE uploading
powershell -File scripts/preview-strip.ps1 -Source C:\images\whole_pfp.png

# OG card for a page
powershell -File scripts/make-og-card.ps1 -Source C:\site\screenshot.png -Out C:\site\public\og.png
```

After generating any image, **look at it** (Read the PNG) and run `preview-strip.ps1` on it. If the subject's head is clipped in the strip, lower `-Scale` (more margin) and regenerate.

## Workflow A — Avatar / profile picture

Use when the user changes a profile pic or a link preview of a profile shows a cropped/old avatar.

1. Get the source. If only a circle-masked or already-cropped version exists, the script flattens it; note that anything the prior mask already clipped is unrecoverable — ask for the full-bleed original if quality matters.
2. (Optional but persuasive) Run `preview-strip.ps1` on the RAW source first and **Read** the output. It produces the "headless" proof that shows the user exactly why their current avatar is being clipped — a useful way to explain the fix before doing it.
3. `reframe-avatar.ps1` (defaults to `-Mode both`). The **`whole_`** variant (figure floated in center band with margin) is the recommendation for anything that feeds a link preview, because the strip crop keeps the whole subject. The **`crop_`** variant is for fixed circle/square slots that never strip-crop (Slack/Discord/portfolio).
4. Verify: run `preview-strip.ps1` on the `whole_` variant and **Read BOTH the `whole_` image AND its `_strip_` output** — the script only prints a path, so you must open the images to judge them. If the head/subject is clipped, lower `-Scale` (more margin) and regenerate.
5. Upload the `whole_` variant, then run **Workflow C (cache-bust)**.

## Workflow B — Page Open Graph card + meta

Use when adding/fixing a page's share preview (portfolio, landing page, deployed app).

1. Check the page's `<head>` for existing OG tags. A **blank** LinkedIn card almost always means **no `og:image`** (or a relative one).
2. `make-og-card.ps1` from a strong screenshot of the page → `public/og.png` (1200x630).
3. Inject `assets/og-meta-template.html` into `<head>`, replacing the `{{PLACEHOLDERS}}`. Keep `og:image` **absolute**. Match the site's existing voice in the copy.
4. Commit/deploy. On GitHub Pages this is push-to-`main` (respect the repo's branch/PR workflow; only push direct to `main` with the user's explicit OK).
5. After deploy, confirm `https://your.domain/og.png` loads, then run **Workflow C**.

## Workflow C — Cache-bust playbook (the step everyone forgets)

A re-scrape of an already-cached URL often returns the platform's stored copy. To force a clean pull:

1. **Change the URL key.** Inspect/share `https://your.url/?v=2` (incrementing query). The host ignores it for display; the platform sees a brand-new cache key and downloads fresh. Use that exact `?v=N` URL going forward.
2. **LinkedIn:** run the **Post Inspector** (`https://www.linkedin.com/post-inspector/`) on the `?v=N` URL. Confirm the returned `Image` is the new one (its `media.licdn.com` URL carries a fresh capture timestamp).
3. **Re-add, don't just re-scrape.** A preview is frozen when an item is *created*. Re-scraping does NOT retro-update an existing Featured item or published post — delete and re-add the Featured link (after the Post Inspector refresh), and delete/repost any pinned post that matters.
4. If the image is *still* stale after a `?v=N` fresh pull, the host's own generated card hasn't regenerated (e.g. GitHub profile card) — make any small profile/page edit to recompute its hash, then re-inspect.

## Worked example: GitHub avatar shows old/cropped in a LinkedIn link preview

This exact case combines BOTH problems and comes up a lot, so here is the end-to-end path:

1. Reframe the source with `reframe-avatar.ps1`; upload the `whole_` variant as the GitHub avatar.
2. **Recompute GitHub's generated card.** GitHub builds a profile's `og:image` at `opengraph.githubassets.com/<hash>/<user>`, and the `<hash>` only changes when the profile changes. After swapping the avatar, make any tiny profile edit (bio, name, a pinned repo) so the hash recomputes — otherwise GitHub keeps serving the old generated card and every downstream scrape inherits it.
3. **Force the sharing platform to re-pull** by inspecting `https://github.com/<user>?v=2` in the LinkedIn Post Inspector. `?v=N` works fine on a *profile* URL, not just pages you control: GitHub ignores the query for display, but LinkedIn treats it as a brand-new cache key and downloads fresh. Increment N on each retry, and use that `?v=N` URL going forward.
4. Delete and re-add the GitHub link in Featured so the fresh card is the one that freezes in.

## Permanent fix for pages you control

Make the `og:image` filename carry a version (`og.png?v=2026-06`) whenever the image changes. Then a re-scrape always sees a new key and it never goes stale again.
