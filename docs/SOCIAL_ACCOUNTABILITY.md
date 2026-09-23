# Social accountability

## A. Partner (1:1)
Friend holds the emergency key. See earlier sections.

## B. Public feed (this option)
Auto posts to **SweatLock’s** social page (recommended) or the user’s own account (optional).

### Why brand page > user’s personal post
| | Brand @SweatLock | User’s own account |
|--|------------------|--------------------|
| Promotion | Every unlock is marketing | Only their followers |
| Embarrassment cost | Still real (named or handle) | Higher — may refuse opt-in |
| Privacy | Server can anonymize (`User_4F2`) | Full identity |
| API | One app token posts for all | Per-user OAuth (X paid tiers) |
| Policy | Clear consent in Settings | Same |

**Recommended v1:** events go to **your** backend → post as **@SweatLock** (or IG/TikTok business) with opt-in display name.

### Triggers
| Event | Example post |
|-------|----------------|
| **Win** — finished workout/steps/read+quiz and unlocked an app | `🔥 Maya just earned TikTok with 25 push-ups. Screen time earned, not stolen. #SweatLock` |
| **Fail** — used a locked app full free window *and* dismissed / timed out without a challenge | `⏳ Someone let the free window run out on Instagram — still locked. Earn it or leave it. #SweatLock` |
| **Streak** (optional) | `7-day earn streak. Body before feed.` |
| **Emergency unlock** (optional, harsh mode) | `Emergency unlock used. One less for today.` |

### Consent levels (must be explicit)
1. **Off** (default)
2. **Wins only** — celebrate unlocks
3. **Wins + fails** — full public pressure (strongest accountability)

Never post without opt-in. Confirm once on first enable.

### Privacy rules
- Default display: first name or random alias, **never** phone/email
- App names: optional (some users won’t want “TikTok” public)
- Fail posts: rate-limit (e.g. max 1 fail post / day) so the brand feed isn’t pure shame spam
- Kill switch in Settings clears queue and disables instantly

### Technical path
```
App event → Hive queue (offline-safe)
         → POST /v1/accountability/events (when online)
         → Server templates + posts to X API (user context OR brand token)
```

X API: create post needs **user access token** (OAuth 2.0 PKCE) for posting *as the user*.  
Brand posts: store app-level credentials server-side only — **never** in the mobile app.

### Product risk
Shame can backfire (uninstall + 1-star). Position as **team energy** (“earn the open”) not “expose losers.” Lead with wins; fails should be light, not cruel.

### Ship order
1. Opt-in UI + local queue + share sheet (now)
2. Backend event intake + @SweatLock poster
3. Optional “post as me” OAuth
4. Analytics on opt-in rate vs retention
