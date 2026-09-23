# Social accountability (design)

## Problem
Solo blockers get uninstalled on a weak day. Products like “friend-held locks” work because **someone else** raises the cost of cheating.

## SweatLock direction: “Accountability Partner”

### V1 (local / invite-ready)
- User generates a **partner code** (or link).
- Partner installs SweatLock and enters the code.
- **Lock events** (app blocked, emergency unlock, schedule override) can notify the partner.
- Partner can **approve emergency unlock** (optional hard mode).

### Mechanics
| Event | Solo | With partner |
|-------|------|----------------|
| Emergency unlock | 1/day self-serve | Requires partner approval or shared budget |
| Uninstall attempt | Soft warning | Partner gets push: “X may have left” |
| Streak break | Private | Optional shared streak |
| Focus schedule | Self | Partner sees compliance % |

### Trust model
- Opt-in only; either side can leave.
- No feed content access — only lock metadata.
- Privacy: store partner pair id + device tokens; no message content.

### Backend (later)
- Node + Postgres: `pairs`, `devices`, `events`
- Push: FCM / APNs
- Until backend ships: UI + local “partner placeholder” + share sheet with deep link `sweatlock://partner?code=`

### Why this fits the X discourse
People already ask friends to change their passwords. Productizing that with **Screen Time integrity + exercise proof** is a stronger moat than greyscale alone.

### Ship order
1. UI + local code generation (this sprint scaffold)
2. Share sheet / deep link
3. Backend pair + push
4. Partner-gated emergency unlock
