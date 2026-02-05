# MicroHelp - Product Roadmap

**Date:** February 2, 2026  
**Author:** Hamna Nimra  
**Version:** 1.0  
**Planning Horizon:** 12 months

---

## Executive Summary

This roadmap outlines MicroHelp's feature development over the next year using the Now/Next/Later framework. Features are prioritized using RICE scoring (Reach, Impact, Confidence, Effort) to maximize value delivery while managing limited resources.

**Current Team:**
- 1 Product Manager (me)
- 2 Engineers (Flutter + Firebase)
- 1 Designer (part-time)
- 1 Marketing/Community (part-time)

**Current State:** MVP in development  
**Launch Target:** End of Month 3  
**First Expansion:** Month 6 (if metrics hit)

---

## Now / Next / Later Framework

### NOW (Months 1-3): MVP Launch
**Goal:** Launch in one neighborhood, prove core concept works

**Features:**
- Auth & profiles
- Post/accept/chat
- Basic safety (verification, trust score, reporting)
- Push notifications
- Manual moderation

**Success Metrics:**
- 75+ active users
- 65%+ request fill rate
- <15 min avg time to help
- 60%+ retention at Week 4

---

### NEXT (Months 4-6): Improve & Expand
**Goal:** Fix issues from MVP, expand to 3-5 neighborhoods

**Features:**
- Scheduled posts (post now, need help later)
- Notification controls (frequency, types)
- Improved safety check-ins
- Social sharing (post to Instagram/Twitter)
- First gamification (badges)
- Web version (basic)

**Success Metrics:**
- 300+ active users across 5 neighborhoods
- 75%+ request fill rate
- 50%+ users in multiple neighborhoods stay active
- 40%+ share completed helps

---

### LATER (Months 7-12): Scale & Monetize
**Goal:** City-wide expansion, introduce premium tier

**Features:**
- Recurring requests ("water plants every Monday")
- Advanced safety (emergency contact integration, location sharing)
- Community features (neighborhood leaderboards, events)
- Premium tier (expanded radius, priority notifications)
- Background check integration
- Telegram bot (Phase 3 of platform integration)
- Email digests (Phase 3 of platform integration)
- Embeddable widgets for neighborhood websites

**Success Metrics:**
- 1,500+ active users city-wide
- 80%+ request fill rate
- 10%+ convert to premium
- NPS >50
- 20%+ of new users from social/platform integrations

---

## Feature Prioritization (RICE Scoring)

### RICE Framework

**R**each: How many users will this impact? (0-10)  
**I**mpact: How much will it impact them? (0.25 = minimal, 0.5 = low, 1 = medium, 2 = high, 3 = massive)  
**C**onfidence: How confident are we? (50%, 80%, 100%)  
**E**ffort: How many person-months? (0.5, 1, 2, 4, etc.)

**RICE Score = (Reach × Impact × Confidence) / Effort**

Higher score = higher priority

---

### NOW Features (RICE Scored)

| Feature | Reach | Impact | Confidence | Effort | RICE | Priority |
|---------|-------|--------|------------|--------|------|----------|
| Auth & Verification | 10 | 3 | 100% | 2 | 15.0 | P0 (Must Have) |
| Post Creation | 10 | 3 | 100% | 1.5 | 20.0 | P0 |
| Feed & Accept | 10 | 3 | 100% | 2 | 15.0 | P0 |
| Chat | 10 | 2 | 100% | 1.5 | 13.3 | P0 |
| Trust Score | 8 | 2 | 80% | 1 | 12.8 | P0 |
| Push Notifications | 9 | 2 | 100% | 1 | 18.0 | P0 |
| Report/Block | 6 | 3 | 100% | 0.5 | 36.0 | P0 (Safety) |
| Profile Photos | 10 | 1 | 100% | 0.5 | 20.0 | P1 |
| Anonymity Toggle | 5 | 1 | 80% | 0.5 | 8.0 | P1 |
| Radius Settings | 3 | 0.5 | 80% | 0.5 | 2.4 | P2 |

**P0 = Must have for MVP**  
**P1 = Nice to have, include if time**  
**P2 = Defer to NEXT phase**

---

### NEXT Features (RICE Scored)

| Feature | Reach | Impact | Confidence | Effort | RICE | Priority |
|---------|-------|--------|------------|--------|------|----------|
| Scheduled Posts | 7 | 2 | 80% | 1 | 11.2 | P0 |
| Notification Controls | 9 | 1 | 100% | 0.5 | 18.0 | P0 |
| Safety Check-ins | 8 | 2 | 80% | 1.5 | 8.5 | P0 |
| Social Sharing (Instagram/Twitter) | 6 | 3 | 50% | 1 | 9.0 | P1 |
| Deep Linking | 8 | 2 | 80% | 0.5 | 25.6 | P1 |
| Discord Bot | 4 | 3 | 50% | 1.5 | 4.0 | P1 |
| Badges (First Help) | 5 | 1 | 50% | 1 | 2.5 | P2 |
| Web Version (Basic) | 4 | 1 | 80% | 2 | 1.6 | P2 |
| Photo Sharing in Chat | 7 | 1 | 80% | 1 | 5.6 | P2 |
| Email Digests | 6 | 0.5 | 50% | 1.5 | 1.0 | P3 |
| Telegram Bot | 3 | 2 | 50% | 1 | 3.0 | P3 |

**Decisions:**
- Scheduled Posts = top priority (solves morning supply issue)
- Notification Controls = critical based on MVP feedback
- **Deep Linking = high ROI** (low effort, high reach, enables viral sharing)
- **Social Sharing = high upside** but uncertain adoption, test small first
- **Discord Bot = niche but high impact** for communities that use it
- Web Version = low priority, focus on mobile + social integration first
- Telegram/Email = Phase 3, test social sharing success first

**Platform Integration Strategy:**
Start with easiest, highest-impact integrations (social sharing + deep linking), then expand to bots/widgets based on demand.

---

### LATER Features (RICE Scored)

| Feature | Reach | Impact | Confidence | Effort | RICE | Priority |
|---------|-------|--------|------------|--------|------|----------|
| Recurring Requests | 6 | 2 | 50% | 2 | 3.0 | P1 |
| Emergency Contact Integration | 8 | 3 | 80% | 2 | 9.6 | P0 (Safety) |
| Premium Tier | 2 | 3 | 50% | 4 | 0.75 | P2 |
| Background Checks | 5 | 3 | 50% | 4 | 1.9 | P3 |
| Community Events | 4 | 1 | 30% | 3 | 0.4 | P3 |
| Leaderboards | 5 | 0.5 | 50% | 1 | 1.25 | P3 |

**Decisions:**
- Emergency Contact = safety feature, prioritize
- Premium Tier = needed for revenue but low confidence in demand
- Background Checks = expensive, low ROI for now

---

## Detailed Roadmap by Quarter

### Q1 2026: MVP Development & Launch

**Month 1: Core Development**
- Week 1-2: Auth, profiles, Firebase setup
- Week 3-4: Post creation, feed, accept flow
- Engineering: 2 devs full-time
- Design: Profile screens, post flow, feed

**Month 2: Polish & Testing**
- Week 1-2: Chat, push notifications, trust score
- Week 3-4: Beta testing with 10 users, bug fixes
- Engineering: 2 devs full-time
- Design: Chat UI, notification designs

**Month 3: Launch**
- Week 1: App store submissions, final polish
- Week 2: Pre-launch marketing (flyers, door hangers)
- Week 3: Soft launch to 50 founding users
- Week 4: Monitor, fix bugs, gather feedback
- Marketing: Full-time recruiting + community building

**Deliverables:**
- iOS + Android apps live
- Firebase backend operational
- 75+ active users in pilot neighborhood
- Safety features functional
- Analytics dashboards set up

**Resources:**
- 2 engineers × 3 months = 6 person-months
- 0.5 designer × 3 months = 1.5 person-months
- 1 PM/founder × 3 months = 3 person-months

---

### Q2 2026: Iteration & Expansion

**Month 4: Post-Launch Fixes**
Based on MVP learnings:
- Fix morning supply issue (scheduled posts)
- Add notification controls
- Improve onboarding (first help badge)
- Engineering: 1.5 dev-months
- Design: 0.5 designer-month

**Month 5: Expansion Prep**
- Select 3 new neighborhoods
- Recruit founding users in each
- Build social sharing features + deep linking
- Build Discord bot (pilot)
- Test in pilot neighborhood
- Engineering: 2.5 dev-months
- Marketing: Neighborhood selection, recruitment

**Month 6: Multi-Neighborhood Launch**
- Launch in 3 new neighborhoods
- Total: 4 neighborhoods
- Deploy social sharing features
- Install Discord bot in 2-3 community servers
- Refine playbook for future launches
- Marketing: 1 person full-time

**Deliverables:**
- 300+ users across 4 neighborhoods
- Scheduled posts feature live
- Social sharing working (Instagram, Twitter, Facebook)
- Deep linking functional
- Discord bot deployed in 3 communities
- Expansion playbook documented

**Resources:**
- 2 engineers × 3 months = 6 person-months
- 0.5 designer × 3 months = 1.5 person-months
- 1 PM × 3 months = 3 person-months
- 1 marketer × 3 months = 3 person-months

---

### Q3 2026: Safety & Web

**Month 7-8: Advanced Safety**
- Emergency contact integration
- Location sharing with trusted contact
- Improved reporting/moderation
- Panic button (Phase 3 feature pulled forward if safety issues)
- Engineering: 3 dev-months
- Design: 1 designer-month

**Month 9: Web Version**
- Flutter web deployment
- Basic functionality (browse, post, chat)
- No mobile-specific features yet
- Engineering: 2 dev-months
- Design: 0.5 designer-month

**Deliverables:**
- Advanced safety features live
- Web app accessible
- Continued neighborhood expansion (aim for 10 total)

**Resources:**
- 2 engineers × 3 months = 6 person-months
- 0.5 designer × 3 months = 1.5 person-months

---

### Q4 2026: Scale & Monetization

**Month 10: Premium Tier**
- Define premium features (expanded radius, priority notifications)
- Stripe integration
- Pricing testing
- Engineering: 2 dev-months

**Month 11: Community Features**
- Recurring requests
- Neighborhood leaderboards
- Helper of the month
- Engineering: 2 dev-months
- Design: 1 designer-month

**Month 12: Scaling Infrastructure**
- Performance optimization
- Better matching algorithms
- Analytics improvements
- Background check integration (3rd party)
- Engineering: 2 dev-months

**Deliverables:**
- Premium tier launched
- 1,500+ users city-wide
- Monetization validated
- Infrastructure scales to 5K users

**Resources:**
- 2 engineers × 3 months = 6 person-months
- 1 designer × 3 months = 3 person-months

---

## Feature Dependencies

### Critical Path

```
Auth/Profiles → Post Creation → Feed/Accept → Chat → Complete
     ↓
Push Notifications (needed for timely responses)
     ↓
Trust Score (needed for safety)
     ↓
Report/Block (needed for safety)
```

**Can't launch without:** Auth, Post, Feed, Chat, Notifications, Trust Score, Report

---

### NEXT Phase Dependencies

```
Scheduled Posts → depends on: Post Creation
                 ↓
          Analytics (what times are best?)

Social Sharing → depends on: Completion flow
                ↓
          Sharable graphics generation

Badges → depends on: Trust Score system
```

---

### LATER Phase Dependencies

```
Recurring Requests → depends on: Scheduled Posts
                    ↓
              Calendar integration

Premium Tier → depends on: Stripe integration
              ↓
        Feature gating logic

Emergency Contacts → depends on: Profile system
                    ↓
              SMS/email alerts
```

---

## Risk Assessment by Feature

### NOW (MVP)

| Feature | Risk | Mitigation |
|---------|------|------------|
| Auth & Verification | **Medium** - SMS delivery issues | Add email backup, use reliable provider |
| Chat | **Low** - Firebase has battle-tested chat | Use existing libraries |
| Trust Score | **Medium** - Gaming system | Server-side validation, rate limiting |
| Push Notifications | **High** - iOS/Android permissions | Clear messaging, request at right time |
| Manual Moderation | **High** - Doesn't scale | Build automated tools in NEXT phase |

---

### NEXT (Iteration)

| Feature | Risk | Mitigation |
|---------|------|------------|
| Scheduled Posts | **Medium** - Complexity | Start simple (24hr limit), expand later |
| Social Sharing | **High** - Uncertain adoption | A/B test, make optional |
| Safety Check-ins | **Medium** - Notification fatigue | Configurable, smart defaults |
| Web Version | **Low** - Flutter Web is mature | Progressive enhancement |

---

### LATER (Scale)

| Feature | Risk | Mitigation |
|---------|------|------------|
| Premium Tier | **High** - Willingness to pay unknown | Survey first, pilot with small group |
| Background Checks | **High** - Expensive, slow | Partner with Checkr, make optional |
| Recurring Requests | **Medium** - Calendar sync complexity | Manual first, automate later |
| Community Events | **High** - Uncertain value | MVP test with single event |

---

## Resource Planning

### Team Assumptions

**Engineers (2):**
- Senior Flutter dev: 1 person
- Mid-level full-stack (Flutter + Firebase): 1 person
- Velocity: 40 hours/week, 75% feature work (25% bugs, meetings, etc.)
- Estimate: 30 productive hours/week per person

**Designer (Part-time, 0.5 FTE):**
- 20 hours/week
- Covers: UX research, UI design, user testing
- Estimate: 15 productive hours/week

**PM (Me, Full-time):**
- 40 hours/week
- Covers: Strategy, roadmap, stakeholders, user research, analytics
- Estimate: Doesn't code, but unblocks team

**Marketer (Part-time, 0.5 FTE, starts Month 3):**
- 20 hours/week
- Covers: Community building, content, events, growth
- Estimate: 15 productive hours/week

---

### Effort Estimates

**NOW Phase (MVP):**
- Total effort: 6 engineer-months + 1.5 designer-months
- Timeline: 3 calendar months
- Feasible with: 2 engineers + 0.5 designer

**NEXT Phase:**
- Total effort: 6 engineer-months + 1.5 designer-months
- Timeline: 3 calendar months
- Feasible with: 2 engineers + 0.5 designer

**LATER Phase:**
- Total effort: 18 engineer-months + 4.5 designer-months
- Timeline: 6 calendar months
- Feasible with: 3 engineers + 0.75 designer (need to hire!)

**Hiring Plan:**
- Month 6: Hire 3rd engineer (if metrics hit)
- Month 9: Bring designer to full-time
- Month 12: Hire 4th engineer (scaling infrastructure)

---

## Success Metrics by Phase

### NOW (MVP Launch)

| Metric | Target | How We Measure |
|--------|--------|----------------|
| Active users | 75+ | Weekly active (post, accept, or chat) |
| Request fill rate | 65%+ | % of posts that get accepted |
| Avg time to help | <15 min | From post creation to acceptance |
| Week 4 retention | 60%+ | % of Week 1 cohort still active |
| Completed helps | 50+ | Total helps marked complete |

**Go/No-Go Decision:** If 4/5 metrics hit, proceed to NEXT. If <3 metrics hit, re-evaluate concept.

---

### NEXT (Expansion)

| Metric | Target | How We Measure |
|--------|--------|----------------|
| Active users | 300+ | Across 4-5 neighborhoods |
| Request fill rate | 75%+ | Should improve with more users |
| New user activation | 50%+ | % who post OR accept within Week 1 |
| Repeat usage | 40%+ | % who use app 3+ times |
| NPS | 40+ | Net Promoter Score survey |

**Go/No-Go Decision:** If metrics hit, proceed to city-wide scaling.

---

### LATER (Scale & Monetize)

| Metric | Target | How We Measure |
|--------|--------|----------------|
| Active users | 1,500+ | City-wide |
| Request fill rate | 80%+ | Mature network |
| Premium conversion | 10%+ | % who upgrade to paid |
| Monthly recurring revenue | $5K+ | 500 × $10/mo |
| Retention (Month 3) | 50%+ | Long-term stickiness |

**Milestone:** If MRR hits $10K/mo, raise seed round to scale to more cities.

---

## Feature Backlog (Not on Roadmap Yet)

Ideas that didn't make the cut but worth revisiting:

**Declined for Now:**
- **Video verification:** Too invasive, unclear value
- **In-app payments/tips:** Makes it transactional, not community
- **Skill matching:** Complexity doesn't justify benefit
- **Multi-language support:** Too early, niche until we scale
- **Desktop app:** Web version sufficient
- **Integration with Ring/Nest:** Cool idea, too niche

**Revisit Later:**
- **Neighborhood analytics dashboard:** For associations/HOAs
- **Integration with TaskRabbit:** For tasks too big for us
- **Pet-specific features:** Validated use case, but niche
- **Elderly care network:** Different product, separate app

---

## Key Decisions & Trade-offs

### Decision 1: Mobile-first, Web Later
**Why:** Most urgent requests happen on the go. Web is nice-to-have.  
**Trade-off:** Limits accessibility for desktop users, but faster launch.

### Decision 2: No Reviews, Only Trust Score
**Why:** Reviews feel transactional. Trust score feels community-driven.  
**Trade-off:** Harder to assess quality, but better for retention.

### Decision 3: Free Forever (Core Features)
**Why:** Community should be accessible. Premium is for convenience.  
**Trade-off:** Slower path to revenue, but stronger moat.

### Decision 4: Hyperlocal First, Expand Slowly
**Why:** Network effects require density.  
**Trade-off:** Slower growth, but sustainable.

### Decision 5: Manual Moderation in MVP
**Why:** Can't automate until we understand patterns.  
**Trade-off:** Doesn't scale, but necessary to learn.

---

## Open Questions for Each Phase

### NOW (MVP):
- [ ] What SMS provider is most reliable? (Twilio vs MessageBird)
- [ ] How do we handle flaky helpers? (No-show protocol)
- [ ] What's the threshold for verification badges? (Phone + Email? ID?)

### NEXT (Expansion):
- [ ] How do we incentivize helpers during morning hours?
- [ ] Should we partner with Buy Nothing Project?
- [ ] What neighborhoods expand to next? (Data-driven selection)

### LATER (Scale):
- [ ] What's the right price for premium? ($5? $10? $15?)
- [ ] Do we want ads as a revenue model? (Probably not, but explore)
- [ ] When do we need to hire a full-time safety/trust person?

---

## How This Roadmap Evolves

**Monthly:**
- Review feature performance
- Update RICE scores based on data
- Re-prioritize NEXT phase features

**Quarterly:**
- Major roadmap review
- Adjust LATER phase based on learnings
- Resource planning (hiring, contractors)

**Annually:**
- Strategic review: Are we building the right product?
- Competitive landscape check
- Validate vision still makes sense

---

## Appendix A: RICE Scoring Template

```
Feature: [Name]
Reach: [0-10] - How many users affected per month?
Impact: [0.25, 0.5, 1, 2, 3] - How much per user?
Confidence: [50%, 80%, 100%] - How sure are we?
Effort: [Person-months] - How long to build?

RICE = (Reach × Impact × Confidence) / Effort

Example:
Feature: Scheduled Posts
Reach: 7 (70% of users would use this)
Impact: 2 (High - solves morning supply problem)
Confidence: 80% (We're pretty sure based on feedback)
Effort: 1 (One engineer, one month)

RICE = (7 × 2 × 0.8) / 1 = 11.2
```

---

## Appendix B: Resource Loading Chart

```
        Q1      Q2      Q3      Q4
Eng 1   ████████████████████████████
Eng 2   ████████████████████████████
Eng 3   ----------------████████████  (Hire Month 6)
Design  ████████████████████████████  (0.5 → 1.0 FTE)
PM      ████████████████████████████
Mktg    --------████████████████████  (Start Month 3)
```

---

**Document Version:** 1.0  
**Next Review:** End of Month 3 (Post-MVP)  
**Owner:** Hamna Nimra
