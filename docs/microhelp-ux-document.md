# MicroHelp - UX Document

**Version:** 1.0
**Last Updated:** February 6, 2026
**Author:** Hamna Nimra
**Status:** Phase 1 - MVP

---

## 1. Product Overview

MicroHelp is a hyperlocal community help app that connects neighbors for small favors and micro-requests. The UX is designed around one principle: **make it as easy to ask a neighbor for help as it is to send a text message.**

**Tagline:** *Small acts, big impact*
**Platform:** Flutter (iOS, Android, Web)
**Design System:** Material Design 3
**Theme Seed Color:** Teal (`Colors.teal`)

---

## 2. Design Principles

### 2.1 Speed Over Polish
Every screen is optimized for getting help fast. The target is post-to-help in under 15 minutes. No unnecessary steps, no long forms, no friction.

### 2.2 Single-Purpose Clarity
MicroHelp does one thing: neighbor help. There are no social feeds, no marketplace, no news. Every pixel serves the core loop: **Post → Accept → Chat → Complete.**

### 2.3 Trust Through Transparency
Safety is built into every interaction. Trust scores, verification badges, gender/age visibility, and anonymity toggles give users control over how much they share while seeing enough about others to feel safe.

### 2.4 Community, Not Transaction
The UX avoids transactional language. No "hire," no "pay," no star ratings. Instead: "help," "trust score," "complete." This keeps it neighborly.

---

## 3. Information Architecture

```
App Launch
├── Splash Screen (1s auto-redirect)
│   ├── [Authenticated] → Home Screen
│   └── [Not Authenticated] → Landing Screen
│
├── Landing Screen
│   ├── Sign Up → Auth Screen (Sign Up mode)
│   └── Sign In → Auth Screen (Sign In mode)
│
└── Home Screen (Bottom Navigation)
    ├── Tab 1: Feed
    │   └── Post Card → Post Detail Screen
    │       ├── Accept → Chat Screen
    │       │   └── Mark Complete → Task Completion Screen
    │       └── Open Chat (if already accepted)
    │
    ├── Tab 2: Post (Create Micro-Help)
    │
    └── Tab 3: Profile
        ├── Edit Profile → Edit Profile Screen
        ├── Badges → Badges Screen
        └── Logout → Landing Screen
```

---

## 4. Screen-by-Screen Specification

### 4.1 Splash Screen

**Purpose:** Brand moment + auth check routing
**Duration:** 1 second auto-redirect
**File:** `lib/screens/splash_screen.dart`

**Layout:**
- Centered vertically
- Volunteer activism icon (80px, teal primary)
- App name "MicroHelp" (headlineMedium, bold)
- Tagline "Small acts, big impact" (bodyLarge, muted)

**Logic:**
- Checks `AuthService.currentUser`
- If signed in → pushReplacement to `HomeScreen`
- If not signed in → pushReplacement to `LandingScreen`

**UX Notes:**
- No loading spinner shown; the icon + text serves as the loading state
- 1-second delay ensures the brand registers even on fast connections

---

### 4.2 Landing Screen

**Purpose:** First impression + auth method selection
**File:** `lib/screens/landing_screen.dart`

**Layout:**
- SafeArea with 24px padding
- Spacer-centered content
- Volunteer activism icon (100px, teal primary)
- App name "MicroHelp" (headlineMedium, bold, centered)
- Subtitle "Give or get help from your neighbors" (bodyLarge, muted, centered)
- Bottom-anchored buttons:
  - **Sign Up** — FilledButton (primary, full-width)
  - **Sign In** — OutlinedButton (full-width)
- 48px bottom padding

**Interactions:**
- Sign Up → navigates to `AuthScreen(initialSignUp: true)`
- Sign In → navigates to `AuthScreen(initialSignUp: false)`

**UX Notes:**
- Sign Up is visually dominant (filled) since new user acquisition is the priority
- Clean, minimal layout avoids overwhelming first-time users
- No onboarding carousel — gets users to auth as fast as possible

---

### 4.3 Auth Screen

**Purpose:** Email/password + social auth
**File:** `lib/screens/auth_screen.dart`

**Layout:**
- AppBar with title ("Sign Up" or "Sign In")
- ScrollView with 24px padding
- Error banner (red text, shown conditionally)
- Email field (OutlinedBorder, email keyboard, envelope icon)
- Password field (OutlinedBorder, obscured, lock icon)
- Submit button (FilledButton, full-width)
  - Shows CircularProgressIndicator (20px) when loading
- Divider with "or" label
- **Continue with Google** — OutlinedButton with Google icon (conditionally shown based on platform)
- **Continue with Apple** — OutlinedButton with Apple icon (conditionally shown on iOS/macOS)
- Toggle link: "Already have an account? Sign In" / "Don't have an account? Sign Up"

**Form Validation:**
- Email: required, non-empty
- Password: required, non-empty

**Auth Methods:**
| Method | Availability |
|--------|-------------|
| Email/Password | All platforms |
| Google Sign-In | Non-Windows platforms |
| Apple Sign-In | iOS and macOS only |

**Post-Auth Flow:**
1. Credential obtained
2. `AuthService.getOrCreateUser()` creates/fetches Firestore user doc
3. `pushAndRemoveUntil` to HomeScreen (clears nav stack)

**Error Handling:**
- Errors display as red text above the form
- "Exception: " prefix is stripped for cleaner messaging
- Loading state disables all buttons to prevent double-submit

**UX Notes:**
- Toggle between Sign Up/Sign In is in-place (no separate screens) to reduce navigation friction
- Social auth buttons appear only on supported platforms (no dead buttons)
- The loading spinner replaces button text, not the entire form, so users know the app is working

---

### 4.4 Home Screen (Main Navigation Shell)

**Purpose:** Primary app container with bottom tab navigation
**File:** `lib/screens/home_screen.dart`

**Layout:**
- `IndexedStack` body (preserves tab state)
- Material 3 `NavigationBar` with 3 destinations:

| Tab | Icon (unselected) | Icon (selected) | Label |
|-----|--------------------|-----------------|-------|
| Feed | `home_outlined` | `home` | Feed |
| Post | `add_circle_outline` | `add_circle` | Post |
| Profile | `person_outline` | `person` | Profile |

**UX Notes:**
- IndexedStack keeps all tabs alive (no reload when switching)
- "Post" tab is centered, making it the primary action (similar to Instagram's "+" pattern)
- Three tabs keeps the navigation simple and scannable

---

### 4.5 Feed Screen

**Purpose:** Browse active help requests and offers
**File:** `lib/screens/feed_screen.dart`

**Layout:**
- AppBar with title "Feed"
- StreamBuilder listening to `FirestoreService.getActivePosts()`
- States:
  - **Loading:** Centered CircularProgressIndicator
  - **Error:** Centered error text
  - **Empty:** "No active posts. Be the first to post!"
  - **Data:** ListView of Cards

**Post Card Design:**
- Card with 16px horizontal margin, 4px vertical margin
- ListTile layout:
  - **Title:** "Request" (orange, bold) or "Offer" (green, bold)
  - **Subtitle:** Description (max 2 lines, ellipsis overflow)
  - **Trailing:** "~X min" estimated time (if provided)
- Tap → navigates to `PostDetailScreen(postId: post.id)`

**Color Coding:**
| Post Type | Color | Rationale |
|-----------|-------|-----------|
| Request | Orange | Urgency, needs attention |
| Offer | Green | Positive, available help |

**Data Source:** Real-time Firestore snapshot stream

**UX Notes:**
- Real-time updates mean new posts appear instantly without pull-to-refresh
- Color-coded type labels let users scan quickly for what they need
- Empty state encourages posting rather than just saying "nothing here"
- Estimated time shown as trailing text helps users gauge commitment before tapping

---

### 4.6 Post Micro-Help Screen

**Purpose:** Create a new help request or offer
**File:** `lib/screens/post_help_screen.dart`

**Layout:**
- AppBar with title "Post Micro-Help"
- ScrollView with 24px padding
- Form fields (top to bottom):

**1. Type Selector**
- Material 3 `SegmentedButton<PostType>`
- Two segments:
  - Request (help_outline icon)
  - Offer (volunteer_activism icon)
- Default: Request

**2. Description**
- TextFormField, multiline (3 lines)
- Max 200 characters (with counter)
- Hint: "What do you need or offer?"
- Validation: required, non-empty

**3. Estimated Time (Optional)**
- DropdownButtonFormField
- Options: Not specified, 15, 30, 45, 60, 90, 120 min
- Default: Not specified

**4. Global Toggle**
- SwitchListTile: "Global (visible to everyone)"
- Default: off

**5. Radius Slider (shown when not global)**
- Range: 1–50 km, 49 divisions
- Label shows current value: "Radius: X km"
- Default: 5 km

**6. Anonymous Toggle**
- SwitchListTile: "Post anonymously"
- Default: off

**7. Expiration Picker**
- ListTile with schedule icon
- Tapping opens DatePicker then TimePicker
- Range: now to 30 days from now
- Default: 24 hours from now
- Displayed as: DD/MM/YYYY HH:00

**8. Submit**
- FilledButton: "Post" (full-width)

**Post Submission Flow:**
1. Validates form
2. If not global → requests device location via Geolocator
3. If location denied/unavailable → shows SnackBar error, aborts
4. Creates `PostModel` and calls `FirestoreService.createPost()`
5. Shows "Post created" SnackBar
6. Clears description field

**UX Notes:**
- SegmentedButton makes type selection tactile and instant
- 200-char limit with visible counter prevents long posts (this is micro-help, not an essay)
- Radius slider only appears when relevant (not global), reducing cognitive load
- Expiration uses native date/time pickers for platform-appropriate input
- Form does NOT navigate away after posting — user stays on Post tab for quick follow-up posts

---

### 4.7 Post Detail Screen

**Purpose:** View full post details and take action (accept / open chat)
**File:** `lib/screens/post_detail_screen.dart`

**Layout:**
- AppBar with title "Post detail"
- FutureBuilder loading post from Firestore
- States:
  - **Loading:** Centered CircularProgressIndicator
  - **Not Found:** "Post not found" text

**Content (when loaded):**
- **Type Chip:** "Request" (orange) or "Offer" (green), white text
- **Description:** bodyLarge text
- **Estimated Time:** "~X min" (if provided)
- **Expiration:** ISO date substring (YYYY-MM-DDTHH:MM)
- **Poster Info:** "Anonymous" or truncated user ID ("User: abc12345...")

**Action Buttons (conditional):**

| User State | Button Shown |
|-----------|-------------|
| Not owner, not accepted, not completed | **Accept** (FilledButton) |
| Owner or helper, not completed | **Open chat** (FilledButton) |
| Completed | **Completed** chip (grey) |

**Accept Flow:**
1. Calls `FirestoreService.acceptPost(postId, uid)`
2. pushReplacement to `ChatScreen(postId)` — replaces detail screen so back button goes to feed

**UX Notes:**
- Single primary action button at any given state prevents confusion
- Accept immediately opens chat — no intermediate confirmation dialog in MVP (speed prioritized)
- Completed state shows a static chip, clearly indicating no further action needed
- Anonymous posts show "Anonymous" instead of user info to respect privacy setting

---

### 4.8 Chat Screen

**Purpose:** Real-time messaging between poster and helper
**File:** `lib/screens/chat_screen.dart`

**Layout:**
- AppBar with title "Chat" and checkmark action button
- Column layout:
  - **Messages area** (Expanded, StreamBuilder)
  - **Input area** (bottom-pinned)

**Messages:**
- Real-time stream from `FirestoreService.getMessages(postId)`
- Bubble layout:
  - Sender's messages: right-aligned, `primaryContainer` color
  - Other's messages: left-aligned, `surfaceContainerHighest` color
  - Both: 16px horizontal padding, 10px vertical, 16px border radius
  - Timestamp shown below text: "HH:MM" format

**Empty State:** "No messages yet. Say hello!"

**Input Area:**
- Row layout:
  - TextField with "Message" hint, OutlinedBorder (Expanded)
  - IconButton.filled with send icon
- Submit on Enter key or send button tap

**AppBar Action:**
- Checkmark icon (`check_circle_outline`) → navigates to `TaskCompletionScreen`
- Always visible in app bar for easy access

**Message Send Flow:**
1. Trim text, validate non-empty
2. Create `MessageModel` with sender ID, text, timestamp
3. Call `FirestoreService.sendMessage(postId, message)`
4. Clear input
5. Auto-scroll to bottom

**UX Notes:**
- Bubble-style chat is universally recognized and requires zero learning
- Color differentiation between sender/receiver is immediate visual parsing
- The task completion button is in the app bar (not buried in a menu) for discoverability
- Auto-scroll ensures the latest message is always visible
- No typing indicators or read receipts in MVP — complexity deferred

---

### 4.9 Task Completion Screen

**Purpose:** Mark a help task as completed
**File:** `lib/screens/task_completion_screen.dart`

**Layout:**
- AppBar with title "Complete task"
- FutureBuilder loading post from Firestore
- Content:
  - Post description (titleMedium)
  - Conditional action area

**States:**

| State | UI |
|-------|----|
| Already completed | Grey chip: "Already completed" |
| Helper or owner, not completed | **Mark as completed** (FilledButton) |
| Other user | Text: "Only the helper or poster can mark this complete." |

**Completion Flow:**
1. Calls `FirestoreService.completePost(postId, uid)`
2. Client-side trust score increment for helper
3. Server-side Cloud Function also increments trust score (ensures consistency)
4. Pops screen back to chat
5. Shows "Task marked complete." SnackBar

**UX Notes:**
- Separate screen (not inline in chat) makes completion feel deliberate, not accidental
- Clear guard: only poster or helper can complete
- Single button with clear label reduces completion errors
- SnackBar confirms the action was successful

---

### 4.10 Profile Screen

**Purpose:** View own profile, trust score, and access settings
**File:** `lib/screens/profile_screen.dart`

**Layout:**
- AppBar with title "Profile" and logout icon button
- StreamBuilder listening to `users/{uid}` document
- Content:
  - **Avatar:** CircleAvatar (48px radius)
    - Shows profile photo if available
    - Falls back to first letter of name (headlineLarge)
  - **Name:** headlineSmall
  - **Trust Score:** Row with verified_user icon + "Trust score: X" (titleMedium)
  - **Edit Profile** button (FilledButton.icon with edit icon)
  - **Badges & gamification** button (OutlinedButton.icon with trophy icon)

**Logout Flow:**
1. Calls `AuthService.signOut()`
2. `pushAndRemoveUntil` to LandingScreen (clears entire nav stack)

**UX Notes:**
- Trust score is prominently displayed as the primary metric — reinforces the trust system
- Profile photo with initial fallback ensures the avatar area never looks broken
- Two clear action buttons: edit profile and badges (no buried menus)
- Logout is in the app bar (standard Material pattern), not a button that could be accidentally tapped

---

### 4.11 Edit Profile Screen

**Purpose:** Update display name
**File:** `lib/screens/edit_profile_screen.dart`

**Layout:**
- AppBar with title "Edit profile"
- 24px padded form
- Display name TextFormField (OutlinedBorder)
- Save button (FilledButton, full-width)

**Save Flow:**
1. Validates non-empty name
2. Updates `users/{userId}` with new name + `lastActive` server timestamp
3. Pops back to Profile screen

**UX Notes:**
- MVP keeps profile editing minimal (name only)
- `lastActive` timestamp updates automatically, tracking engagement
- Immediate pop on save provides instant feedback

---

### 4.12 Badges Screen

**Purpose:** Display trust score and earned badges
**File:** `lib/screens/badges_screen.dart`

**Layout:**
- AppBar with title "Badges & gamification"
- Nested StreamBuilders:
  - User document (for trust score)
  - Badges subcollection (`users/{userId}/badges`)

**Content:**
- **Trust Score Card:**
  - Card with 24px padding
  - Verified user icon (48px, primary color)
  - "Trust score" label (titleMedium)
  - Score value (headlineMedium)

- **Badges Section:**
  - "Badges" heading (titleLarge)
  - Empty state: "No badges yet. Complete tasks to earn badges!"
  - Badge list: ListTile per badge with trophy icon, name, and description

**UX Notes:**
- Trust score is displayed large and prominent — this is the primary gamification mechanic
- Empty badge state encourages action rather than just showing emptiness
- Badges subcollection allows for flexible badge system expansion without schema changes

---

## 5. Core User Flows

### 5.1 New User Onboarding

```
App Open → Splash (1s) → Landing Screen → Sign Up → Auth Screen
→ Enter email + password (or social auth) → getOrCreateUser()
→ Home Screen (Feed tab)
```

**Total taps to first feed view:** 3 (Sign Up → enter credentials → submit)
**Target time:** Under 60 seconds

---

### 5.2 Requesting Help (Happy Path)

```
Home (Feed tab) → Tap "Post" tab → Select "Request"
→ Type description → (Optional: set time, radius, anon, expiry)
→ Tap "Post" → Location permission granted → Post created
→ Wait for acceptance notification → Chat opens
→ Coordinate with helper → Help received
→ Chat app bar → Task Completion → "Mark as completed"
```

**Minimum taps:** 4 (Post tab → type description → Post → Mark complete)

---

### 5.3 Offering Help (Happy Path)

```
Home (Feed tab) → See request card → Tap card
→ Post Detail Screen → Tap "Accept"
→ Chat Screen opens → Coordinate → Provide help
→ Chat app bar → Task Completion → "Mark as completed"
```

**Minimum taps:** 4 (Tap card → Accept → checkmark → Mark complete)

---

### 5.4 Repeat Connection Flow

```
Feed → See familiar poster → Accept → Chat (recognize each other)
→ Help → Complete → Trust score increases
```

**Design goal:** The flow is identical whether it's the first interaction or the tenth. Familiarity builds through repeated simple interactions, not through added complexity.

---

## 6. Navigation Model

### Navigation Type: Bottom Tab + Push Stack

| Navigation Pattern | Usage |
|-------------------|-------|
| Bottom tabs | Feed, Post, Profile (main sections) |
| Push navigation | Detail screens, chat, completion, edit, badges |
| Push replacement | Auth → Home (clears auth stack) |
| Push and remove until | Logout → Landing (clears everything) |

### Back Button Behavior

| From | Back Goes To |
|------|-------------|
| Post Detail | Feed |
| Chat (from accept) | Feed (pushReplacement) |
| Chat (from open chat) | Post Detail |
| Task Completion | Chat |
| Edit Profile | Profile |
| Badges | Profile |
| Auth | Landing |

---

## 7. Visual Design System

### 7.1 Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| Seed Color | Teal | Generated via `ColorScheme.fromSeed()` |
| Primary | Teal (Material 3 generated) | Buttons, icons, accents |
| Primary Container | Light teal | Sender chat bubbles |
| Surface Container Highest | Light grey | Receiver chat bubbles |
| Error | Red (Material 3 default) | Error text, validation |
| Request Color | `Colors.orange` | Request type labels |
| Offer Color | `Colors.green` | Offer type labels |

### 7.2 Typography

Material 3 default type scale:

| Style | Usage |
|-------|-------|
| headlineMedium (bold) | App name on splash/landing |
| headlineSmall | User name on profile |
| headlineLarge | Avatar fallback letter |
| titleLarge | Section headers (badges) |
| titleMedium | Trust score, post descriptions |
| bodyLarge | Subtitles, descriptions |
| bodySmall | Timestamps, metadata |

### 7.3 Spacing

| Constant | Value | Usage |
|----------|-------|-------|
| Screen padding | 24px | All screen content areas |
| Card margin (horizontal) | 16px | Feed cards |
| Card margin (vertical) | 4px | Feed cards |
| Element spacing | 8-24px | Between form fields, sections |
| Chat bubble padding | 16px H, 10px V | Message bubbles |
| Chat bubble radius | 16px | Rounded corners |
| Bottom nav padding | 48px | Landing screen bottom space |

### 7.4 Component Patterns

| Component | Usage |
|-----------|-------|
| FilledButton | Primary actions (submit, accept, save) |
| OutlinedButton | Secondary actions (sign in, social auth, badges) |
| FilledButton.icon | Edit profile |
| OutlinedButton.icon | Badges link, social auth |
| SegmentedButton | Request/Offer toggle |
| SwitchListTile | Boolean toggles (global, anonymous) |
| Card + ListTile | Feed post cards |
| Chip | Type labels, completion status |
| TextFormField (Outlined) | All text inputs |
| DropdownButtonFormField | Estimated time selection |
| CircleAvatar | Profile photo |
| NavigationBar | Bottom tabs |

---

## 8. State Management

### Provider Architecture

```
MultiProvider
├── NotificationService (Provider)
├── AuthService (ProxyProvider, depends on NotificationService)
└── FirestoreService (Provider)
```

### Real-Time Data

| Screen | Data Source | Update Method |
|--------|-----------|---------------|
| Feed | `getActivePosts()` | Firestore snapshot stream |
| Profile | `users/{uid}` | Firestore snapshot stream |
| Chat | `getMessages(postId)` | Firestore snapshot stream |
| Badges | `users/{uid}` + `badges` subcollection | Firestore snapshot streams |
| Post Detail | `getPost(postId)` | FutureBuilder (one-time fetch) |
| Task Completion | `getPost(postId)` | FutureBuilder (one-time fetch) |

---

## 9. Data Models (UX-Relevant Fields)

### User Model
| Field | Type | UX Display |
|-------|------|-----------|
| name | String | Profile header, avatar fallback |
| profilePic | String? | Profile avatar, feed (future) |
| trustScore | int | Profile, badges screen |
| lastActive | DateTime? | Updated on profile edit |
| location | GeoPoint? | Post proximity (future) |

### Post Model
| Field | Type | UX Display |
|-------|------|-----------|
| type | PostType (request/offer) | Color-coded label |
| description | String (200 max) | Feed card subtitle, detail |
| anonymous | bool | "Anonymous" vs user ID |
| estimatedMinutes | int? | "~X min" trailing text |
| expiresAt | DateTime | Expiry display on detail |
| radius | double | Slider value (1-50 km) |
| global | bool | Hides radius slider |
| acceptedBy | String? | Determines button state |
| completed | bool | Shows completed chip |

### Message Model
| Field | Type | UX Display |
|-------|------|-----------|
| senderId | String | Left/right alignment |
| text | String | Bubble content |
| timestamp | DateTime | "HH:MM" below text |

---

## 10. Accessibility Considerations

### Current Implementation
- Material 3 components include built-in accessibility (semantic labels, touch targets)
- High-contrast color coding (orange/green on white cards)
- Text inputs have labels and prefix icons for dual signaling
- Form validation provides text-based error messages

### Recommended Improvements (Future)
- Add `Semantics` widgets for screen reader support on custom layouts
- Ensure all icon buttons have `tooltip` properties
- Test with TalkBack (Android) and VoiceOver (iOS)
- Add high-contrast theme option
- Support dynamic type scaling

---

## 11. Performance Considerations

### Implemented
- `IndexedStack` keeps tabs alive (no re-render on switch)
- Firestore streams provide real-time updates without polling
- `StreamBuilder` and `FutureBuilder` handle loading/error states
- 200-char description limit keeps data payloads small

### Recommended Improvements (Future)
- Add pagination to feed (currently loads all active posts)
- Compress profile images before upload
- Cache user profiles locally for offline viewing
- Add pull-to-refresh on feed as a manual fallback

---

## 12. Known UX Gaps (MVP Limitations)

These are intentional omissions for MVP speed, with planned solutions:

| Gap | Current State | Planned Solution |
|-----|-------------|-----------------|
| No feed filters | Shows all active posts | Add type + distance filters |
| No post deletion | Users can't remove posts | Add delete button (top support ticket) |
| No post editing | Posts are immutable | Allow radius/expiry edits |
| No profile photos | Upload not implemented | Add image picker + Firebase Storage |
| Poster identity | Shows truncated user ID | Show name + avatar from user doc |
| No distance display | Feed cards don't show distance | Calculate + display "X mi away" |
| No map view | Post detail has no map | Add approximate location map |
| No notification controls | All notifications on/off | Add granular notification settings |
| No confirmation on accept | Accept is immediate | Add safety reminder dialog |
| Single-party completion | Either party can mark complete | Require both parties to confirm |
| No report/block | Not implemented in UI | Add report button on profiles + posts |
| No scheduled posts | Post only for now | Add "need help at X time" scheduling |

---

## 13. UX Metrics & Success Criteria

### Usability Targets (from User Research Plan)
- **System Usability Scale (SUS):** >68 (above average)
- **Net Promoter Score (NPS):** >40
- **Task Completion Rate:** >90% for core flows

### Behavioral Targets (from 4-Week Post-Launch Data)
| Metric | Target | Actual (Week 4) | Status |
|--------|--------|-----------------|--------|
| Active users | 75+ | 87 | Exceeds |
| Request fill rate | 80% | 65% | Below |
| Avg time to help | <15 min | 22 min | Below |
| Repeat helper rate | 40%+ | 42% | Exceeds |
| Week 4 retention | 60%+ | 68% | Exceeds |

### Key UX Findings from Post-Launch Data
1. **Morning supply shortage:** 50% fill rate for 6am-12pm posts vs 79% for 3pm-6pm
2. **Anonymity decreases with trust:** 52% of new users post anonymously vs 12% of users with 6+ trust score
3. **Hyperlocal works:** 89% of posts use default 0.5mi radius
4. **Chat is efficient:** Average 8.3 messages per completed help
5. **Low disputes:** Only 4% of completions had disputes

---

## 14. Screen Flow Diagrams

### Authentication Flow
```
┌──────────┐     ┌──────────────┐     ┌─────────────┐     ┌────────────┐
│  Splash   │────>│   Landing    │────>│    Auth      │────>│    Home    │
│  Screen   │     │   Screen     │     │   Screen     │     │   Screen   │
│           │     │              │     │              │     │            │
│ Check auth│     │ Sign Up/In   │     │ Email/Google │     │ Feed tab   │
│ 1s delay  │     │ buttons      │     │ /Apple auth  │     │ active     │
└──────────┘     └──────────────┘     └─────────────┘     └────────────┘
      │
      │ (if already signed in)
      └─────────────────────────────────────────────────────────────────>┘
```

### Core Help Loop
```
┌──────────┐     ┌──────────────┐     ┌─────────────┐     ┌────────────┐
│   Feed   │────>│ Post Detail   │────>│    Chat     │────>│  Complete  │
│  Screen  │     │   Screen      │     │   Screen    │     │   Screen   │
│          │     │               │     │             │     │            │
│ Tap card │     │ Accept button │     │ Coordinate  │     │ Mark done  │
└──────────┘     └──────────────┘     └─────────────┘     └────────────┘
```

### Profile Management
```
┌──────────┐     ┌──────────────┐
│ Profile  │────>│ Edit Profile │
│  Screen  │     │   Screen     │
│          │     │ Update name  │
│          │     └──────────────┘
│          │     ┌──────────────┐
│          │────>│   Badges     │
│          │     │   Screen     │
│          │     │ Trust + list │
└──────────┘     └──────────────┘
```

---

## 15. Future UX Roadmap

### Phase 2 (Months 4-6)
- Feed filtering (type, distance)
- Profile photos + richer identity
- Notification controls
- Safety check-in reminders
- Social sharing (Instagram, Twitter)
- Scheduled posts
- First help badge gamification

### Phase 3 (Months 7-12)
- Map view for nearby requests
- Recurring requests
- Emergency contact integration
- Premium tier UX (expanded radius, priority notifications)
- Leaderboards
- Background check badge tier

---

**Document Version:** 1.0
**Next Review:** Post Phase 2 launch
**Owner:** Hamna Nimra
