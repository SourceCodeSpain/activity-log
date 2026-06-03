# Releasing an update (SourceCode fork)

This is a fork of **Activity Log** that updates itself from this GitHub repo
instead of wordpress.org. To ship a change to live sites, you publish a new
**release** here and the sites pick it up automatically.

## TL;DR — the one command

After you've edited and saved your code changes:

```bash
bin/release.sh <new-version> "<changelog line>" ["<another line>" ...]
```

Example:

```bash
bin/release.sh 2.11.4-sc "Fix: avoid notice when IP is empty" "Tweak: faster query"
```

The script bumps the version, writes the changelog, commits, pushes, and
creates the GitHub release. It shows you the diff and asks for confirmation
before anything is pushed.

## What "matters" vs. what's optional

| Step | Required? | Why |
| --- | --- | --- |
| Bump `Version:` in `aryo-activity-log.php` | ✅ Yes | The site compares this to the release to decide if there's an update. |
| Create a GitHub release tagged `vX.Y.Z-sc` | ✅ Yes | The updater (Plugin Update Checker) only sees **releases**. No release = no update. |
| `Stable tag:` in `readme.txt` | Recommended | Keep it equal to the version for consistency. |
| Changelog entry in `readme.txt` | Optional | Shows in the "View details" popup in WP admin. Documentation only. |
| `Tested up to:` in `readme.txt` | Optional | Bump only after you've confirmed a newer WordPress works. |

`bin/release.sh` handles all of these for you.

## Versioning

- Keep the **`-sc`** suffix so it's clearly your build and can never be
  "downgraded" to the wordpress.org copy.
- Increment the last number for normal fixes: `2.11.3-sc → 2.11.4-sc`.

## How a site receives the update

1. You publish a release here.
2. Within ~12 hours each site sees "update available" for **Activity Log
   (SourceCode)** (force it now via **WP Admin → Dashboard → Updates → Check
   again**).
3. Click update — it installs like any normal plugin.

> First time only: a site must already be running this fork build (the one
> with the `Update URI` header + bundled updater). After that, updates are
> automatic. If a host blocks the in-dashboard updater (e.g. a
> `wp-content/upgrade` permissions error), install once manually by extracting
> the plugin zip into `wp-content/plugins/`.

## Doing it by hand (if you ever skip the script)

1. Edit code.
2. `aryo-activity-log.php` → bump `Version:`.
3. `readme.txt` → bump `Stable tag:` and add a `= X.Y.Z-sc - YYYY-MM-DD =`
   block at the top of `== Changelog ==`.
4. `git add -A && git commit -m "X.Y.Z-sc: ..." && git push`
5. `gh release create vX.Y.Z-sc --target master --title vX.Y.Z-sc --notes "..."`

## Pulling in fixes from upstream later

The original project lives at `elementor/activity-log`. If it ever revives:

```bash
git remote add upstream https://github.com/elementor/activity-log.git
git fetch upstream
git merge upstream/master      # resolve conflicts in the header/updater bits
```

Then cut a new `-sc` release as above.
