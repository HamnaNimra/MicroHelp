# MicroHelp - Data Analysis: 4-Week Post-Launch Review

**Date:** March 30, 2026  
**Analysis Period:** March 2 - March 29, 2026 (4 weeks post-launch)  
**Analyst:** Hamna Nimra  
**Distribution:** Internal team + advisors

---

## Executive Summary

**TL;DR:** Launch is showing promise but has critical issues. Request fill rate is below target (65% vs 80% goal), but repeat helper rate is strong (42%). Main problem: supply-side shortage during weekday mornings. Recommendation: Recruit 20 more helpers + implement time-based notifications.

**Key Metrics:**
- 87 active users (target: 75+) ✅
- 156 total posts created
- 102 helps completed (65% fill rate, target: 80%) ⚠️
- Average time to help: 22 minutes (target: <15 min) ⚠️
- 42% repeat helper rate (target: 40%) ✅
- Week 4 retention: 68% (target: 60%+) ✅

**Decision:** Continue with adjustments. Core concept is validated, execution needs refinement.

---

## Data Sources

**Firebase Analytics:**
- User events (signup, post, accept, complete)
- Session data
- Crash reports

**Firestore Queries:**
- Posts collection
- Users collection
- Messages collection
- Reports collection

**Mixpanel:**
- Funnel analysis
- Cohort retention
- User segmentation

**Manual:**
- User interviews (10 users interviewed)
- Support tickets (23 total)

---

## 1. User Acquisition & Activation

### Signups Over Time

| Week | New Signups | Total Active Users | Growth Rate |
|------|-------------|-------------------|-------------|
| Week 1 | 52 | 52 | - |
| Week 2 | 23 | 71 | +44% |
| Week 3 | 12 | 79 | +11% |
| Week 4 | 8 | 87 | +10% |

**Analysis:**
- Strong initial wave (52 users from founding cohort)
- Growth slowed significantly after Week 1
- Week 4 growth is organic (word-of-mouth only)
- Need to restart marketing efforts

**Chart:** [Line graph showing new signups declining week over week]

---

### Activation Funnel

| Step | Users | Conversion Rate |
|------|-------|-----------------|
| Downloaded app | 95 | 100% |
| Completed signup | 87 | 92% |
| Verified phone | 82 | 86% |
| Created profile | 79 | 83% |
| Viewed feed | 74 | 78% |
| Posted OR accepted | 68 | 72% |

**Drop-off Points:**
1. **Phone verification (6% drop):** Some users don't receive SMS code, use Google Voice numbers
2. **Profile creation (4% drop):** Photo upload is slow on bad connections
3. **First action (6% drop):** Users browse but don't engage

**Recommendations:**
- Add email verification as backup for phone issues
- Compress profile photos before upload
- Add onboarding prompt: "Post your first request" with examples

---

### User Demographics (n=87)

**Age Range:**
- 18-25: 8 users (9%)
- 26-35: 52 users (60%) ← **Core demographic**
- 36-45: 19 users (22%)
- 46-55: 6 users (7%)
- 56+: 2 users (2%)

**Gender:**
- Female: 49 users (56%)
- Male: 35 users (40%)
- Non-binary: 2 users (2%)
- Prefer not to say: 1 user (1%)

**Living Situation (from onboarding survey):**
- Lives alone: 38 users (44%)
- With partner: 29 users (33%)
- With roommates: 12 users (14%)
- With family: 8 users (9%)

**Tenure in Neighborhood:**
- <1 year: 31 users (36%)
- 1-3 years: 42 users (48%) ← **Majority**
- 3+ years: 14 users (16%)

**Key Insight:** We're hitting our target demographic (25-35, recently moved, lives alone/with partner). Slight female skew is good for safety perception.

---

## 2. Engagement & Usage Patterns

### Posts Created

**Total:** 156 posts over 4 weeks (39 posts/week average)

**By Type:**
- Requests: 134 (86%)
- Offers: 22 (14%)

**Analysis:** Heavy skew toward requests. Need to incentivize more offers.

---

### Post Category Breakdown

| Category | Count | % of Total |
|----------|-------|------------|
| Borrow items (tools, ingredients) | 47 | 30% |
| Car help (jump, flat tire) | 23 | 15% |
| Pet care (walk dog, feed cat) | 19 | 12% |
| Package receipt | 18 | 12% |
| Moving/lifting help | 16 | 10% |
| Plant watering | 14 | 9% |
| Quick errands | 11 | 7% |
| Other | 8 | 5% |

**Top 3 Categories:**
1. **Borrowing items** (30%) - validates core use case
2. **Car help** (15%) - urgent, high-value
3. **Pet care** (12%) - validates safety net hypothesis

**Insight:** Mix of planned (plant watering) and urgent (car help) requests. Good balance.

---

### Request Fill Rate Analysis

**Overall:** 102 helps completed out of 156 posts = **65% fill rate**

**Target:** 80%  
**Gap:** -15 percentage points ⚠️

**By Time Posted:**

| Time of Day | Posts | Filled | Fill Rate |
|-------------|-------|--------|-----------|
| 6am-9am (Morning) | 28 | 14 | 50% ⚠️ |
| 9am-12pm (Late Morning) | 31 | 19 | 61% ⚠️ |
| 12pm-3pm (Afternoon) | 34 | 24 | 71% |
| 3pm-6pm (Evening) | 38 | 30 | 79% ✅ |
| 6pm-9pm (Night) | 19 | 13 | 68% |
| 9pm-6am (Late Night) | 6 | 2 | 33% ⚠️ |

**Key Finding:** Mornings have terrible fill rates (50-61%). Evenings are strong (79%).

**Hypothesis:** Most helpers are checking app after work (3pm-6pm). Morning requests sit unfulfilled.

---

### Time to First Response

**Average:** 22 minutes (target: <15 min)

**Distribution:**
- <5 min: 23 posts (23%)
- 5-15 min: 34 posts (33%)
- 15-30 min: 28 posts (27%)
- 30-60 min: 12 posts (12%)
- >60 min: 5 posts (5%)

**56% of posts get response within 15 min** (target threshold). Not terrible, but needs improvement.

**By Time Posted (Average Response Time):**
- Morning: 38 minutes ⚠️
- Afternoon: 18 minutes
- Evening: 14 minutes ✅

**Insight:** Evening posts get fastest responses. Morning posts languish.

---

### Posts That Expired (No Helper)

**54 posts expired** without being accepted (35% of all posts)

**Common Characteristics:**
- 71% were posted during morning hours (6am-12pm)
- 48% were "moving/lifting" requests (too big?)
- 22% had vague descriptions ("need help with something")
- 15% were from users with 0 trust score (new users)

**Sample Expired Posts:**
- "Need someone to help move couch" (too big, requires 2 people)
- "Anyone free?" (too vague)
- "Borrow a ladder" at 7am (bad timing)

**Recommendations:**
1. Prompt users to be specific in descriptions
2. Warn about posting large tasks ("This might be too big for MicroHelp. Try TaskRabbit?")
3. Suggest better timing ("Morning posts have lower response rates. Post in evening?")

---

### Helper Activity

**Active Helpers:** 48 users have accepted at least one request (55% of user base)

**Passive Users:** 39 users have never accepted (45%)

**Helper Distribution:**
- 1 help completed: 22 users (46%)
- 2-3 helps: 15 users (31%)
- 4-5 helps: 7 users (15%)
- 6+ helps: 4 users (8%) ← **Power helpers**

**Top Helper:** User #1047 has completed 11 helps in 4 weeks (2.75 helps/week)

**Key Insight:** We have a supply-side problem. Only 55% have helped at all. 45% are pure takers.

---

### Repeat Helper Rate

**42% of completed helps** involved a repeat connection (poster and helper had interacted before)

**Target:** 40%+  
**Status:** ✅ Exceeding target

**Examples:**
- User #1023 has helped User #1019 three times (borrow sugar, jump car, water plants)
- User #1047 has helped 6 different neighbors, 3 of them multiple times

**Qualitative Feedback:**
- "I now know Sarah next door, we chat when we see each other"
- "Helped Mark with his dog twice, he brought me cookies to say thanks"
- "It's nice to have someone I can ask when I need something"

**Insight:** Core thesis is validated. Small helps ARE building real relationships.

---

## 3. Retention Analysis

### Weekly Retention Cohorts

| Cohort | Week 1 | Week 2 | Week 3 | Week 4 |
|--------|--------|--------|--------|--------|
| Week 1 (n=52) | 100% | 77% | 73% | 68% |
| Week 2 (n=23) | 100% | 83% | 78% | - |
| Week 3 (n=12) | 100% | 75% | - | - |

**Week 4 Retention:** 68% (target: 60%+) ✅

**Chart:** [Retention curve showing Week 1 cohort declining to 68% by Week 4]

**Analysis:**
- Retention is above target
- Biggest drop is Week 1 → Week 2 (23% churn)
- Retention stabilizes after Week 2

---

### Churn Analysis

**Total Churned Users:** 17 users (19% of Week 1 cohort)

**Churn Reasons (from exit interviews, n=8):**
- "Didn't need help during this time" (3 users)
- "My posts never got answered" (2 users) ← **Fixable**
- "Too many notifications" (1 user) ← **Fixable**
- "Felt weird asking strangers" (1 user)
- "Moved out of neighborhood" (1 user)

**Recommendations:**
1. Allow users to snooze notifications ("I don't need help this month")
2. Improve morning fill rates so posts get answered
3. Add notification settings (frequency control)

---

### Active Users Definition

**Daily Active Users (DAU):** 12 users/day average  
**Weekly Active Users (WAU):** 68 users/week  
**Monthly Active Users (MAU):** 87 users

**DAU/MAU Ratio:** 14% (low, but expected for infrequent-use app)

**Insight:** This isn't a daily-use app like Instagram. People open it when they need help, not for entertainment. That's okay.

---

## 4. Feature Usage

### Anonymity Toggle

**Posts with anonymity enabled:** 47 out of 156 (30%)

**Analysis:** Significant portion want anonymity. Feature is being used.

**By user trust score:**
- Trust score 0-2: 52% use anonymity
- Trust score 3-5: 31% use anonymity
- Trust score 6+: 12% use anonymity

**Insight:** New users are shy. As trust score builds, they become comfortable showing their name.

---

### Radius Settings

**Default (0.5 mi):** 89% of posts  
**Neighborhood (2 mi):** 9% of posts  
**City-wide (10 mi):** 2% of posts  
**Global:** 0% of posts

**Analysis:** Users overwhelmingly keep default. Hyperlocal is working as intended.

---

### Chat Engagement

**Total messages sent:** 847 messages across 102 completed helps  
**Average messages per help:** 8.3 messages

**Distribution:**
- 1-5 messages: 43 helps (42%) - quick coordination
- 6-10 messages: 38 helps (37%) - normal chat
- 11-20 messages: 16 helps (16%) - longer chat
- 20+ messages: 5 helps (5%) - became friends?

**Sample Chat (anonymized):**
```
Helper: "Hey! I've got cables, be there in 5"
Poster: "Amazing thank you! I'm in the red car"
Helper: "Found you, popping the hood"
[10 minutes later]
Poster: "You're a lifesaver, seriously thank you"
Helper: "No problem! Glad it worked"
```

**Insight:** Chats are functional, not social. People coordinate, help, thank, done. Efficient.

---

### "Mark Complete" Behavior

**Both confirmed immediately:** 76 helps (75%)  
**One confirmed, other delayed:** 22 helps (22%)  
**Dispute:** 4 helps (4%)

**Disputes:**
- 2 = helper no-show (released back to feed)
- 1 = poster claimed help wasn't adequate
- 1 = miscommunication on time

**Resolution:**
- 3 resolved amicably (both marked complete)
- 1 still under admin review

**Insight:** Dispute rate is very low (4%). Completion flow works.

---

## 5. Safety & Trust

### Reports Filed

**Total:** 4 reports (out of 87 users, 4.6% report rate)

**Categories:**
- No-show (helper accepted but didn't come): 2 reports
- Inappropriate message: 1 report
- Spam post: 1 report

**Resolution:**
- 2 no-shows: Dinged trust score (-1), warned users
- 1 inappropriate message: User apologized, no action
- 1 spam: Post deleted, user warned

**Insight:** Very low report rate. Community is behaving well.

---

### Trust Score Distribution

| Trust Score | Users | % of Users |
|-------------|-------|------------|
| 0 (no helps) | 39 | 45% |
| 1-2 | 23 | 26% |
| 3-5 | 17 | 20% |
| 6-10 | 7 | 8% |
| 11+ | 1 | 1% |

**Analysis:**
- 45% haven't helped anyone yet (pure takers or waiting for right request)
- Top helper has score of 11 (outlier, but impressive)
- Most helpers are in 1-5 range

**Recommendation:** Incentivize first help. Gamification could work (badge for first help).

---

### Verification Status

**Phone verified:** 82 users (94%)  
**Email verified:** 79 users (91%)  
**Both verified:** 76 users (87%)

**Unverified users:** 11 users (13%)

**Unverified user behavior:**
- 2 have posted requests (both ignored - trust issue?)
- 0 have accepted requests
- Low engagement overall

**Recommendation:** Require both verifications to post/accept. Currently optional, should be mandatory.

---

## 6. Qualitative Insights

### User Interviews (n=10)

**Positive Feedback:**
- "Finally met my neighbors!" (5 users mentioned this)
- "So much easier than knocking on doors" (3 users)
- "Love that people actually show up" (4 users)
- "Helped someone and they brought me cookies" (1 user)

**Negative Feedback:**
- "My morning posts never get answered" (6 users) ← **Critical**
- "Wish I could see who's online" (2 users)
- "Notifications are too frequent" (2 users)
- "Some posts are too vague" (1 user)

**Feature Requests:**
- Schedule posts for later (3 users)
- See who's active/online (2 users)
- Recurring requests ("water plants every week") (2 users)
- Photo sharing in chat (2 users)

---

### Support Tickets (n=23)

**Categories:**
- "SMS verification not working" (8 tickets) ← **Top issue**
- "How do I delete a post?" (4 tickets)
- "Someone didn't show up" (3 tickets)
- "Can I change my radius after posting?" (2 tickets)
- "Notification spam" (2 tickets)
- Other (4 tickets)

**Recommendations:**
1. Fix SMS verification (switch provider or add email backup)
2. Add "Delete post" button to post detail screen
3. Allow editing radius after posting
4. Better notification controls

---

## 7. Cohort Comparison

### Early Adopters vs Late Joiners

| Metric | Week 1 Cohort (n=52) | Week 2-4 Cohort (n=35) |
|--------|----------------------|------------------------|
| Avg posts created | 2.1 | 0.8 |
| Avg helps completed | 1.4 | 0.6 |
| % who have helped | 67% | 37% |
| Week 4 retention | 68% | 78% |

**Analysis:**
- Early adopters are WAY more engaged (2.1 posts vs 0.8)
- But late joiners have BETTER retention (78% vs 68%)
- Late joiners are observers (lurking until they need help)

**Hypothesis:** Early adopters were pre-sold (founding cohort). Late joiners need proof before engaging.

**Recommendation:** Show social proof to new users ("87 neighbors helped this week")

---

## 8. Geographic Heatmap

**Posts by Street:**

| Street | Posts | Helps Completed | Fill Rate |
|--------|-------|-----------------|-----------|
| Maple Ave | 34 | 26 | 76% |
| Oak St | 28 | 21 | 75% |
| Pine Dr | 22 | 18 | 82% ✅ |
| Elm Rd | 19 | 11 | 58% ⚠️ |
| Cedar Ln | 12 | 8 | 67% |
| Other streets | 41 | 18 | 44% ⚠️ |

**Analysis:**
- Core 5 streets have good density (68-82% fill rate)
- Outlying streets have poor fill rate (44%)
- Network effects work at density

**Recommendation:** Focus growth on core 5 streets before expanding to periphery.

---

## 9. Key Findings & Recommendations

### Critical Issues (Must Fix)

**Issue #1: Morning Supply Shortage**
- **Problem:** 50-61% fill rate for 6am-12pm posts
- **Impact:** 35% of all posts expire
- **Root cause:** Helpers check app after work, not during work hours
- **Recommendation:**
  1. Implement time-based push notifications ("You have helpers available near you now")
  2. Recruit 20 more helpers who are home during mornings (WFH, parents, retirees)
  3. Allow scheduling posts for later ("I'll need help at 6pm, post it at 5pm")

**Issue #2: SMS Verification Failures**
- **Problem:** 8 support tickets, 6% drop-off at verification step
- **Impact:** Lost users at critical onboarding moment
- **Recommendation:**
  1. Switch SMS provider (Twilio → MessageBird)
  2. Add email verification as backup
  3. Better error messaging ("Didn't get code? Try email instead")

**Issue #3: Passive Users (45% Never Help)**
- **Problem:** Only 55% of users have accepted a request
- **Impact:** Supply shortage, especially mornings
- **Recommendation:**
  1. Gamification: Badge for first help ("Helpful Neighbor")
  2. Prompt after browsing 3 posts: "See something you can help with?"
  3. Highlight how good it feels: "Mark helped 3 neighbors this week"

---

### Validated Hypotheses ✅

1. **People want hyperlocal help** - 87 users in 4 weeks validates demand
2. **Small helps build relationships** - 42% repeat rate proves it
3. **Safety features work** - Only 4 reports, 4.6% rate is very low
4. **Retention is strong** - 68% Week 4 retention exceeds target
5. **Core use cases are correct** - Borrowing, car help, pet care are top 3

---

### Opportunities (Nice to Have)

1. **Recurring requests** - "Water plants every Monday" (3 user requests)
2. **Scheduled posts** - Post in evening for morning help
3. **Photo sharing** - Show the broken thing in chat
4. **Online indicator** - See who's active now
5. **Badges/gamification** - Reward frequent helpers

---

## 10. Recommendations & Next Steps

### Immediate Actions (This Week)

1. **Fix SMS verification** - Switch provider, add email backup
2. **Recruit morning helpers** - Post in WFH Facebook groups, target parents
3. **Add "Delete post" button** - #1 support ticket
4. **Notification controls** - Let users set frequency

### Short-Term (Next 4 Weeks)

1. **Implement scheduled posts** - Allow posting for later times
2. **Add social proof** - Show activity to new users
3. **First help badge** - Gamify first acceptance
4. **Improve post quality** - Prompts for clear descriptions
5. **Evening growth push** - Market to evening users (best fill rate)

### Medium-Term (Next 8 Weeks)

1. **Photo sharing in chat** - Requested by multiple users
2. **Recurring requests** - For weekly plant watering, etc.
3. **Helper leaderboard** - Recognize top contributors
4. **Expand to 2-3 new streets** - Once core streets hit 80% fill rate

---

## 11. Success Metrics Review

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Active users | 75+ | 87 | ✅ Exceed |
| Request fill rate | 80% | 65% | ⚠️ Below |
| Time to help | <15 min | 22 min | ⚠️ Below |
| Repeat helper rate | 40%+ | 42% | ✅ Exceed |
| Week 4 retention | 60%+ | 68% | ✅ Exceed |
| Completed helps | 50+ | 102 | ✅ Exceed |

**Overall:** 4/6 metrics hit target. Core concept validated, execution needs refinement.

---

## 12. Go-Forward Decision

**DECISION: GREEN LIGHT - CONTINUE WITH ADJUSTMENTS**

**Rationale:**
- User acquisition exceeds target (87 vs 75)
- Retention is strong (68%)
- Repeat connections prove community building works
- Helps are happening (102 in 4 weeks)
- Safety issues are minimal (4 reports)

**Issues are solvable:**
- Morning supply shortage → recruit + notifications
- SMS verification → switch provider
- Passive users → gamification

**Not issues:**
- Core concept (people want this)
- Safety (users feel safe)
- Retention (people stick around)

---

## Appendix A: Data Queries Used

```sql
-- Total posts by week
SELECT 
  DATE_TRUNC('week', createdAt) as week,
  COUNT(*) as posts
FROM posts
GROUP BY week
ORDER BY week;

-- Fill rate by time of day
SELECT 
  CASE 
    WHEN EXTRACT(HOUR FROM createdAt) BETWEEN 6 AND 9 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM createdAt) BETWEEN 9 AND 12 THEN 'Late Morning'
    -- etc
  END as time_period,
  COUNT(*) as total_posts,
  SUM(CASE WHEN acceptedBy IS NOT NULL THEN 1 ELSE 0 END) as filled,
  ROUND(100.0 * SUM(CASE WHEN acceptedBy IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 0) as fill_rate
FROM posts
GROUP BY time_period;

-- Repeat helper rate
SELECT 
  COUNT(DISTINCT CONCAT(userId, '-', acceptedBy)) as unique_pairs,
  COUNT(*) as total_helps,
  ROUND(100.0 * (COUNT(*) - COUNT(DISTINCT CONCAT(userId, '-', acceptedBy))) / COUNT(*), 0) as repeat_rate
FROM posts
WHERE completed = true;

-- User retention
WITH cohorts AS (
  SELECT 
    userId,
    DATE_TRUNC('week', createdAt) as cohort_week
  FROM users
),
activity AS (
  SELECT DISTINCT
    userId,
    DATE_TRUNC('week', timestamp) as activity_week
  FROM events
  WHERE event_name IN ('post_created', 'request_accepted', 'message_sent')
)
SELECT 
  c.cohort_week,
  COUNT(DISTINCT c.userId) as cohort_size,
  COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort_week + INTERVAL '1 week' THEN c.userId END) as week_1_retained,
  COUNT(DISTINCT CASE WHEN a.activity_week = c.cohort_week + INTERVAL '2 weeks' THEN c.userId END) as week_2_retained
FROM cohorts c
LEFT JOIN activity a ON c.userId = a.userId
GROUP BY c.cohort_week
ORDER BY c.cohort_week;
```

---

## Appendix B: User Interview Quotes

**On morning supply shortage:**
> "I posted at 8am needing jumper cables before work. Nobody responded for 2 hours. By then I'd already called AAA." - User #1029

> "I work from home so I check the app during breaks. But most posts are from mornings when I'm heads-down working." - User #1047

**On repeat connections:**
> "Sarah helped me with my plants last week, so when she posted about needing an egg I immediately said yes. It's nice to have someone I can count on." - User #1023

> "I've helped the same guy twice now. We actually text sometimes now outside the app. He's cool." - User #1051

**On safety:**
> "As a woman, I really appreciate seeing gender before accepting. I only accept requests from women or during daytime." - User #1033

**On community impact:**
> "I've lived here 2 years and never knew anyone. In 4 weeks I've met 5 neighbors. This actually works." - User #1019

---

**Document Version:** 1.0  
**Next Review:** April 30, 2026 (8-week post-launch)
