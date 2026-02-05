# MicroHelp - Product Requirements Document (PRD)

**Version:** 1.0  
**Last Updated:** February 2, 2026  
**Author:** Hamna Nimra  
**Status:** Phase 1 - MVP Development

---

## Executive Summary

MicroHelp is a hyperlocal community help app that connects neighbors for small favors and micro-requests. The app aims to rebuild casual community connections by making it easy to ask for and offer help within walking distance.

**Target Launch:** Q2 2026 (MVP)  
**Initial Market:** Single neighborhood pilot (50-100 users)  
**Platform:** Flutter (iOS, Android, Web)  
**Backend:** Firebase

---

## Problem Statement

After COVID, communities have become increasingly isolated. People don't know their neighbors, tech has eliminated reasons for casual interaction, and critical community safety nets have disappeared. Real consequences include:
- Pets dying when owners are deported/hospitalized because neighbors don't know
- Depression increasing as tech usage increases
- Emergency situations where no one checks in
- Loss of casual community that used to make neighborhoods safer

---

## Product Vision

Bring back the world where people knew their neighbors. Not forced friendships, but the safety net of actual community: knowing who lives around you, being able to ask for help without awkwardness, having people who notice if something's wrong.

---

## Success Metrics

### North Star Metric
**Completed Helps Per Week** - If neighbors are helping each other regularly, we're rebuilding community.

### Supporting Metrics
1. **Time to Help:** Average minutes from post to completion (Target: <15 min)
2. **Request Fill Rate:** % of requests that get accepted (Target: 80%+ within 30 min)
3. **Repeat Connections:** % of users who help/request from same neighbor twice
4. **Weekly Active Helpers:** Number of people actively helping each week

---

## User Personas

### Primary: The Isolated Professional
- Age: 25-35
- Lives alone or with partner
- Works from home or hybrid
- Moved during/after COVID, friends scattered
- Has everything delivered, rarely interacts with neighbors
- Feels low-level isolation but not crisis loneliness

### Secondary: The Busy Parent
- Age: 30-45
- Young kids, tight schedule
- Needs occasional quick help (watch kid for 10 min, borrow ingredients)
- Wants to know neighbors for safety/community
- Time-poor, looking for low-commitment connections

### Tertiary: The Retiree/Elder
- Age: 60+
- May live alone, kids moved away
- Needs help with physical tasks (carrying groceries, changing lightbulbs)
- Has time to help others, wants to feel useful
- Values community, remembers "the old days" when neighbors helped

### Quaternary: The Community Builder
- Age: Any
- Naturally helpful, wants to contribute
- Misses sense of neighborhood community
- Motivated by being needed and visible generosity

**Key Insight:** MicroHelp serves ALL ages. Young people need community. Old people need help AND want to help. Parents need flexibility. Everyone benefits from knowing their neighbors.

---

## MVP Scope (Phase 1)

### Core Features

#### 1. Authentication
**Must Have:**
- Email/password signup
- Google OAuth
- Apple Sign-In
- Phone number verification (SMS)
- Email verification

**User Flow:**
1. User downloads app
2. Chooses auth method
3. Enters phone number → receives SMS code
4. Enters email → receives verification link
5. Creates profile (name, photo, age range, gender)
6. Sets location permissions

**Firebase Implementation:**
- `FirebaseAuth.createUserWithEmailAndPassword()`
- `FirebaseAuth.signInWithCredential()` for Google/Apple
- Store user data in `users/{userId}` collection

---

#### 2. User Profile

**Required Fields:**
- Name (first name + last initial public)
- Profile photo
- Age range (18-25, 26-35, 36-45, 46-55, 56-65, 65+)
- Gender (Male, Female, Non-binary, Prefer not to say)
- Location (GeoPoint, lat/long)
- Phone number (verified)
- Email (verified)

**Auto-Generated Fields:**
- Trust score (starts at 0)
- Account created date
- Last active timestamp
- Total helps completed
- Total requests completed

**Optional Fields:**
- Bio (100 chars max)
- Social media links (for additional verification)

**Privacy Settings:**
- Show exact age vs age range (default: age range only)
- Show last name (default: no)
- Allow anonymous posts (default: yes)

**Firestore Structure:**
```
users/{userId}
  name: string
  profilePic: string (URL)
  ageRange: string
  gender: string
  location: GeoPoint
  phoneVerified: boolean
  emailVerified: boolean
  trustScore: number (default: 0)
  accountCreated: timestamp
  lastActive: timestamp
  totalHelpsCompleted: number
  totalRequestsCompleted: number
  bio: string (optional)
  allowAnonymous: boolean
```

---

#### 3. Post Micro-Help

**User Flow:**
1. Tap "+" button on feed
2. Choose type: Request or Offer
3. Enter description (200 char max)
4. Select location settings:
   - Default: Walking distance (0.5 mi)
   - Options: Neighborhood (2 mi), City (10 mi), Global
5. Toggle anonymity (default: not anonymous)
6. Optional: Add estimated time
7. Set expiration (default: 24 hours, options: 1hr, 6hr, 12hr, 24hr, 48hr)
8. Post

**Post Fields:**
- Type: "request" | "offer"
- Description: string (max 200 chars)
- UserId: string (poster)
- Location: GeoPoint
- Radius: number (in miles)
- Global: boolean
- Anonymous: boolean
- EstimatedTime: number (minutes, optional)
- ExpiresAt: timestamp
- CreatedAt: timestamp
- AcceptedBy: string | null
- AcceptedAt: timestamp | null
- Completed: boolean
- CompletedAt: timestamp | null
- Status: "active" | "accepted" | "completed" | "expired"

**Firestore Structure:**
```
posts/{postId}
  type: "request" | "offer"
  description: string
  userId: string
  location: GeoPoint
  radius: number
  global: boolean
  anonymous: boolean
  estimatedTime: number
  expiresAt: timestamp
  createdAt: timestamp
  acceptedBy: string | null
  acceptedAt: timestamp | null
  completed: boolean
  completedAt: timestamp | null
  status: string
```

**Validation Rules:**
- Description: 5-200 characters
- Radius: 0.5, 2, 10, or 9999 (global)
- ExpiresAt: Must be future timestamp
- Rate limiting: Max 5 posts per user per day

---

#### 4. Feed

**Display Logic:**
1. Fetch posts where `status === "active"` and `expiresAt > now`
2. Filter by distance (client-side):
   - Calculate distance between user location and post location
   - Show only posts within radius
3. Sort by: Closest first, then newest
4. Real-time updates via Firestore snapshots

**Feed Card Shows:**
- Type indicator (Request 🙏 | Offer 🤝)
- Description
- Distance (0.2 mi away)
- Time posted (2 min ago)
- Estimated time (if provided)
- Poster info:
  - Anonymous: "Someone nearby" + gender + age range + trust score
  - Not anonymous: Name + photo + gender + age range + trust score
- Verification badge (if phone + email verified)

**User Actions:**
- Tap card → View detail
- Pull to refresh
- Filter: Requests only, Offers only, All
- Filter: Distance (0.5mi, 2mi, 10mi, Global)

**Firebase Query:**
```javascript
posts
  .where('status', '==', 'active')
  .where('expiresAt', '>', now)
  .orderBy('expiresAt')
  .limit(50)
```

Client-side filters distance based on user's current location.

---

#### 5. Post Detail & Accept

**Post Detail Screen Shows:**
- Full description
- Map view (approximate location, not exact address)
- Poster profile:
  - Photo (if not anonymous)
  - Name (if not anonymous) or "Anonymous"
  - Gender, age range
  - Trust score
  - Account age
  - Verification badges
- Estimated time
- Distance from you
- Posted time
- Expires in X hours

**Accept Flow:**
1. User taps "Accept & Chat"
2. Confirmation dialog:
   - "You're committing to help [name/anonymous person]. They'll be notified immediately."
   - Safety reminder: "Share your location with a trusted contact before meeting"
3. On confirm:
   - Post.acceptedBy = userId
   - Post.acceptedAt = timestamp
   - Post.status = "accepted"
   - Create chat thread
   - Send push notification to poster
   - Remove post from feed for other users

**Firestore Transaction:**
```javascript
const postRef = db.collection('posts').doc(postId);
await db.runTransaction(async (transaction) => {
  const postDoc = await transaction.get(postRef);
  if (postDoc.data().acceptedBy !== null) {
    throw new Error('Already accepted by someone else');
  }
  transaction.update(postRef, {
    acceptedBy: userId,
    acceptedAt: FieldValue.serverTimestamp(),
    status: 'accepted'
  });
});
```

**Security Rule:**
Only one user can accept (enforced in Firestore rules).

---

#### 6. Chat

**Chat Screen:**
- Shows messages between poster and helper only
- Real-time message updates
- Text input only (no images/files in MVP)
- Optional: "Share My Location" button
- "Mark Task Complete" button (both users must confirm)

**Message Structure:**
```
messages/{postId}/messages/{messageId}
  senderId: string
  text: string
  timestamp: timestamp
  read: boolean
```

**Chat Features:**
- Send text message
- See read receipts
- Share live location (optional, temporary)
- Mark complete when done

**Firebase Implementation:**
```javascript
// Send message
await db.collection('messages').doc(postId)
  .collection('messages')
  .add({
    senderId: userId,
    text: messageText,
    timestamp: FieldValue.serverTimestamp(),
    read: false
  });

// Listen to messages
db.collection('messages').doc(postId)
  .collection('messages')
  .orderBy('timestamp', 'asc')
  .onSnapshot((snapshot) => {
    // Update UI
  });
```

**Security Rules:**
```javascript
match /messages/{postId}/messages/{messageId} {
  allow read, write: if 
    request.auth.uid == get(/databases/$(database)/documents/posts/$(postId)).data.userId ||
    request.auth.uid == get(/databases/$(database)/documents/posts/$(postId)).data.acceptedBy;
}
```

---

#### 7. Task Completion

**Completion Flow:**
1. Either user taps "Mark Complete" in chat
2. Request goes to other user: "Did you complete this task?"
3. Both users must confirm
4. On both confirmations:
   - Post.completed = true
   - Post.completedAt = timestamp
   - Post.status = "completed"
   - Cloud Function increments helper's trust score
   - Optional: Request photo proof
   - Push notification: "Task completed! You earned +1 trust score"

**Trust Score Calculation (Cloud Function):**
```javascript
exports.incrementTrustScore = functions.firestore
  .document('posts/{postId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    if (newData.completed && !oldData.completed) {
      const helperRef = db.collection('users').doc(newData.acceptedBy);
      await helperRef.update({
        trustScore: FieldValue.increment(1),
        totalHelpsCompleted: FieldValue.increment(1)
      });
      
      const posterRef = db.collection('users').doc(newData.userId);
      await posterRef.update({
        totalRequestsCompleted: FieldValue.increment(1)
      });
    }
  });
```

---

#### 8. Push Notifications (Firebase Cloud Messaging)

**Notification Triggers:**
1. New post nearby (within user's radius preference)
2. Your post was accepted
3. New message in chat
4. Task marked complete
5. Trust score increased

**Implementation:**
- Store FCM tokens in user profile
- Send via Firebase Cloud Functions
- User can toggle notification preferences in settings

**Cloud Function Example:**
```javascript
exports.sendPostNotification = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, context) => {
    const post = snap.data();
    
    // Query nearby users
    const usersSnapshot = await db.collection('users')
      .where('location', '>=', /* geopoint calculation */)
      .get();
    
    const tokens = [];
    usersSnapshot.forEach(doc => {
      if (doc.data().fcmToken) {
        tokens.push(doc.data().fcmToken);
      }
    });
    
    const message = {
      notification: {
        title: 'Someone nearby needs help',
        body: post.description.substring(0, 100)
      },
      data: {
        postId: context.params.postId,
        type: 'new_post'
      },
      tokens: tokens
    };
    
    await admin.messaging().sendMulticast(message);
  });
```

---

## Trust & Safety Features (MVP)

### 1. Verification System
- Phone verification (required)
- Email verification (required)
- Visible verification badges on profiles

### 2. Profile Transparency
- Gender visible before accepting
- Age range visible before accepting
- Trust score visible (# of completed helps)
- Account age visible
- Verification status visible

### 3. Reporting & Blocking
- Report button on every profile/post/chat
- Block user (hides their posts, prevents contact)
- Report categories:
  - Spam
  - Harassment
  - Safety concern
  - Inappropriate content
  - Fake profile
  - Scam/fraud

**Report Structure:**
```
reports/{reportId}
  reporterId: string
  reportedUserId: string
  reportedPostId: string (optional)
  category: string
  description: string
  timestamp: timestamp
  status: "pending" | "reviewed" | "actioned"
```

### 4. Safety Check-ins (Phase 2)
- Mark Safe button after task
- Emergency contact notifications
- Panic button

### 5. Content Moderation
- Profanity filter on posts/messages
- Auto-flag posts with certain keywords
- Manual review queue for flagged content

---

## Technical Architecture

### Frontend: Flutter
- Single codebase for iOS, Android, Web
- State management: Riverpod or Provider
- Maps: Google Maps Flutter plugin
- Push notifications: firebase_messaging package
- Location: geolocator package

### Backend: Firebase
- **Authentication:** Firebase Auth
- **Database:** Cloud Firestore
- **Storage:** Firebase Storage (profile pics)
- **Functions:** Cloud Functions (trust score, notifications, moderation)
- **Hosting:** Firebase Hosting (web version)
- **Analytics:** Firebase Analytics
- **Crashlytics:** Firebase Crashlytics

### Database Schema

See Firestore structures defined in each feature section above.

---

## User Flows

### Happy Path: Request Help
1. User opens app
2. Taps "+" to create post
3. Selects "Request"
4. Types: "Need jumper cables, car won't start"
5. Sets radius: 0.5 mi (default)
6. Posts (not anonymous)
7. Neighbor sees notification
8. Neighbor views post detail
9. Neighbor taps "Accept & Chat"
10. Chat opens, they coordinate
11. Neighbor arrives, helps jump car
12. Both mark task complete
13. Helper gets +1 trust score
14. Optional: Both rate experience

### Edge Cases

**Post expires before acceptance:**
- Auto-delete from feed
- Send notification to poster: "Your request expired. Want to repost?"

**Helper accepts but doesn't show:**
- Poster can "Report No-Show" after 30 min
- Post releases back to feed
- Helper's trust score dinged (-1)
- If 3 no-shows, account suspended pending review

**Dispute after completion:**
- Either user can dispute within 24 hours
- Opens admin review ticket
- Both users submit evidence
- Admin makes final call on trust score

**Spam/abuse:**
- Auto-suspend after 2 reports (pending review)
- Permanent ban for verified violations
- Appeal process via email

---

## Phase 1 MVP - Out of Scope

### Platform Integration Features (Phase 2)

**Philosophy:** Don't compete with social platforms, integrate with them. Meet users where they already are.

#### Social Media Sharing
Post completed helps to Instagram, Twitter, Facebook with auto-generated graphics.

**User Flow:**
1. Task marked complete
2. Prompt: "Share your good deed?" with preview
3. Select platform (Instagram Story, Twitter, Facebook)
4. Auto-generated card shows:
   - "I just helped my neighbor [task type]!"
   - Trust score badge
   - MicroHelp branding + deep link
5. Post directly or save to camera roll

**Implementation:**
- Generate shareable image (Canvas API or server-side image generation)
- Deep links format: `microhelp://post/{postId}`
- Falls back to web: `https://microhelp.app/post/{postId}`
- Track shares in analytics

**Why This Matters:**
- Organic growth (friends see, download app)
- Social proof (helping becomes visible)
- Virality without ads
- Competitor apps don't do this (Nextdoor shares are just screenshots)

---

#### Discord/Slack Bot Integration
Post nearby requests to existing community servers/channels.

**How It Works:**
1. Neighborhood Discord server installs MicroHelp bot
2. Bot watches for new posts within configured radius
3. Posts to designated channel: "🆘 Someone 0.3 mi away needs jumper cables"
4. Members click link → opens app (or web) → can accept

**Implementation:**
- Discord bot (discord.js)
- Slash commands: `/microhelp setup`, `/microhelp radius 2mi`
- Webhook from Firebase when new post created
- Rate limiting (max 5 posts/hour to avoid spam)

**Use Cases:**
- Apartment building Discord servers
- Neighborhood Slack workspaces
- Gaming communities (local chapter channels)

**Why This Matters:**
- Reach people who aren't checking the app
- Leverage existing community infrastructure
- Lower barrier (no new app to check)

---

#### Telegram Group Bot
Similar to Discord but for Telegram neighborhood groups.

**How It Works:**
1. Add @MicroHelpBot to neighborhood Telegram group
2. Bot posts nearby requests automatically
3. Members tap link → app opens → accept

**Implementation:**
- Telegram Bot API
- Similar logic to Discord bot
- Respects group rules (can be muted/unmuted)

**Why This Matters:**
- Huge in certain communities (immigrant neighborhoods, international users)
- Many neighborhood groups already on Telegram
- Alternative to Facebook Groups

---

#### Embeddable Widget (Web)
Neighborhood websites can embed "Nearby Requests" widget.

**What It Is:**
HTML iframe widget showing active requests in area.

**Implementation:**
```html
<iframe 
  src="https://microhelp.app/widget?zip=90210&radius=2" 
  width="100%" 
  height="400px">
</iframe>
```

**Widget shows:**
- 5 most recent requests
- "X people need help nearby"
- Click → opens app or web

**Use Cases:**
- HOA websites
- Neighborhood association sites
- Apartment building portals
- Community center websites

**Why This Matters:**
- Distribution through existing community sites
- Legitimacy (official neighborhood site promotes you)
- Reach older demographics (who visit websites, not apps)

---

#### Email Digests
Daily/weekly summary of nearby posts for non-active-app-users.

**User Flow:**
1. User opts in to digest (or default on)
2. Receives email daily at 8am: "3 neighbors need help today"
3. Email shows brief description + "Accept" button
4. Clicks → opens app → accept flow

**Implementation:**
- Cloud Function runs daily (Firebase Scheduler)
- Query posts from last 24 hours within user's radius
- SendGrid/Mailgun for sending
- Track: open rate, click rate, accepts from email

**Personalization:**
- Frequency setting (daily, weekly, never)
- Only send if there are posts (no empty emails)
- Highlight posts matching user's past helps

**Why This Matters:**
- Re-engage dormant users
- Reach people who don't check apps daily
- Reminder that community needs help

---

#### Deep Linking (All Platforms)
Every post has a shareable link that opens the app.

**Format:**
- Web: `https://microhelp.app/post/{postId}`
- Universal Link (iOS): Opens app if installed, web if not
- App Link (Android): Same behavior

**Use Cases:**
- Share specific request via text message
- Post link in WhatsApp group chat
- Tweet link to followers
- Email link to neighbor

**Implementation:**
- Firebase Dynamic Links (easiest)
- Or custom deep link handler
- Web version handles fallback

**Why This Matters:**
- Request can go viral beyond app users
- Lower friction (share via any platform)
- Competitors don't support this well

---

### Phase 2 Social Integration Roadmap

**Month 4-5:**
- Social sharing (Instagram, Twitter, Facebook)
- Deep linking infrastructure
- Analytics tracking

**Month 6:**
- Discord bot (pilot with 2-3 servers)
- Email digests (MVP version)

**Month 7-8:**
- Telegram bot
- Embeddable widget (beta)

**Month 9:**
- Slack integration (if demand)
- Refine based on usage data

---

### Success Metrics (Phase 2 Social)

**Social Sharing:**
- 30%+ of completed helps shared
- 5%+ of app downloads from social referrals
- Viral coefficient >0.2 (each user brings 0.2 new users)

**Discord/Telegram Bots:**
- 10+ communities using bots
- 15%+ of posts get accepted via bot link
- Bot installs as channel for new user acquisition

**Email Digests:**
- 40%+ open rate
- 10%+ click rate
- 5%+ accepts initiated from email

**Widget:**
- 20+ websites using widget
- 100+ clicks per month per widget
- Measurable traffic from widget referrals

---

## Phase 1 MVP - Out of Scope

### Features NOT in Phase 1:
- Badges/gamification (Phase 2)
- Social media sharing (Phase 2)
- Web embeddable widgets (Phase 2)
- Email digests (Phase 2)
- Telegram/Discord bots (Phase 2)
- Photo sharing in chat (Phase 2)
- Multi-language support (Phase 3)
- Payment/tipping (Phase 3)
- Background checks (Phase 3)
- Community events (Phase 3)
- Group helps (Phase 3)

---

## Launch Plan

### Pre-Launch (Week -4 to Week 0)
1. **Select pilot neighborhood:**
   - Walkable area (~1 sq mile)
   - Mixed demographics
   - Active local Facebook group or NextDoor presence
   - Access to neighborhood association

2. **Recruit founding users (Target: 50-100):**
   - Door hangers with QR code
   - Coffee shop flyers
   - Post in local Facebook groups
   - Attend neighborhood association meeting
   - Offer "Founding Neighbor" badge

3. **Set up analytics:**
   - Firebase Analytics events
   - Mixpanel or Amplitude for funnel tracking
   - Weekly metric dashboard

### Launch Week (Week 0)
- Soft launch to founding users
- Daily check-ins on usage
- Fix critical bugs immediately
- Monitor all completed helps manually
- Collect qualitative feedback

### Post-Launch (Week 1-8)
- Weekly metric reviews
- Bi-weekly user interviews (5 users)
- Iterate based on feedback
- Fix bugs and UX issues
- Add minor features based on demand

### Success Criteria for Phase 2
- 75+ active users in pilot neighborhood
- 50+ completed helps in first month
- 70%+ request fill rate
- <10% churn rate
- Net Promoter Score >40

If these are hit, expand to 2-3 more neighborhoods and build Phase 2 features.

---

## Open Questions / Decisions Needed

### Technical
1. **Geohashing vs client-side distance filtering?**
   - Geohashing = faster queries but harder to implement
   - Client-side = simpler but slower with many posts
   - **Decision:** Start with client-side, migrate to geohashing if performance issues

2. **How to handle location privacy?**
   - Show exact location in chat after accept?
   - Or always show approximate (within 0.1 mi)?
   - **Decision:** Approximate until chat, then share exact address via message

3. **Photo proof requirement?**
   - Optional or required for trust score?
   - **Decision:** Optional in MVP, required in Phase 2 for high-value tasks

### Product
1. **What if both users want to mark incomplete?**
   - Open dispute flow
   - Admin reviews evidence
   - Neither gets trust score

2. **Should we allow tips/payment?**
   - Phase 1: No. Keep it community-based, not transactional
   - Phase 3: Maybe. Survey users first

3. **Max active posts per user?**
   - Limit to prevent spam
   - **Decision:** 3 active posts max at once

---

## Risks & Mitigation

### Risk 1: Not enough users in pilot area
**Impact:** Network effects don't work, no one gets helped  
**Likelihood:** Medium  
**Mitigation:** 
- Over-recruit founding users (target 100, need 50)
- Manually match first 10-20 requests if needed
- Host in-person kickoff event

### Risk 2: Safety incident
**Impact:** Bad press, user churn, legal liability  
**Likelihood:** Low but high impact  
**Mitigation:**
- Robust verification (phone + email)
- Clear safety guidelines
- Emergency contact features
- Insurance coverage
- Clear Terms of Service with liability waiver

### Risk 3: Spam/abuse
**Impact:** User experience degrades, trust erodes  
**Likelihood:** Medium  
**Mitigation:**
- Rate limiting (5 posts/day)
- Report + block features
- Manual review of flagged content
- Auto-suspend after 2 reports

### Risk 4: Users don't trust the system
**Impact:** Low adoption, high abandonment  
**Likelihood:** Medium  
**Mitigation:**
- Show trust score prominently
- Verification badges
- Founding user testimonials
- In-person kickoff builds initial trust

---

## Success Criteria

### Phase 1 MVP (8 weeks)
- ✅ 75+ active users in pilot neighborhood
- ✅ 50+ completed helps
- ✅ 70%+ request fill rate within 30 minutes
- ✅ <15 minute average time to help
- ✅ 20%+ users help same neighbor twice
- ✅ <10% weekly churn
- ✅ Zero critical safety incidents
- ✅ Net Promoter Score >40

### Phase 2 Decision Point
If Phase 1 criteria are met, proceed to:
- Expand to 3-5 neighborhoods
- Add gamification (badges, streaks)
- Build social sharing features
- Launch web version
- Add email digests

---

## Timeline

### Weeks 1-2: Setup & Design
- Finalize designs (Figma)
- Set up Firebase project
- Set up Flutter project structure
- Define Firestore schema

### Weeks 3-6: Core Development
- Auth flow (email, Google, Apple, phone verification)
- User profile creation/editing
- Post creation/feed/detail
- Accept & chat functionality
- Task completion flow
- Push notifications

### Weeks 7-8: Testing & Polish
- End-to-end testing
- Security rule testing
- Performance optimization
- Bug fixes
- App store submissions

### Week 9: Pre-Launch
- Recruit founding users
- Set up analytics
- Print door hangers
- Create launch materials

### Week 10: Launch
- Soft launch to founding users
- Daily monitoring
- Bug fixes

### Weeks 11-18: Iteration
- Weekly metric reviews
- User interviews
- Feature improvements
- Expand if metrics hit

---

## Appendix

### Design Mockups
[Link to Figma file]

### Firebase Setup Checklist
- [ ] Create Firebase project
- [ ] Enable Authentication (Email, Google, Apple)
- [ ] Create Firestore database
- [ ] Write security rules
- [ ] Set up Cloud Functions
- [ ] Configure FCM
- [ ] Set up Firebase Storage
- [ ] Enable Analytics
- [ ] Add iOS app
- [ ] Add Android app
- [ ] Add web app

### App Store Requirements
**iOS:**
- Privacy policy URL
- Support URL
- App screenshots (6.5" and 5.5")
- App icon (1024x1024)
- Age rating
- Content descriptions

**Android:**
- Privacy policy URL
- Content rating questionnaire
- Screenshots (phone, tablet)
- Feature graphic (1024x500)
- App icon (512x512)

---

**Document Version History:**
- v1.0 (Feb 2, 2026): Initial PRD for MVP
