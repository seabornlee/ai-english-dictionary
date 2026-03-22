# TODOS — AI Dictionary

## Phase 2: Operational Infrastructure (Next Sprint)

### 1. Auto-Updater (Sparkle)
**What:** Integrate Sparkle framework for one-click app updates  
**Why:** Users on old versions = support burden; manual DMG re-download is friction  
**Pros:** Critical for retention; standard Mac app practice; cheap to add now  
**Cons:** ~30 min implementation; requires update feed hosting  
**Context:** Sparkle 2.x is modern, Sandboxing-compatible. Add `SPUStandardUpdaterController` to app delegate. Host appcast XML on GitHub Releases or S3.  
**Effort:** S (human: 4h / CC: 20min)  
**Priority:** P1  
**Depends on:** Phase 1 complete, GitHub Releases workflow stable  
**Blocked by:** None

### 2. Analytics (PostHog)
**What:** Track DAU, feature usage, retention cohorts  
**Why:** "If you can't measure it, you can't improve it" — validate product decisions with data  
**Pros:** Privacy-focused (can self-host); free tier generous; SDK is simple  
**Cons:** ~20 min implementation; adds network calls  
**Context:** Track: app opens, Command+D usage, vocabulary adds, API latency. Use `posthog-ios` SDK.  
**Effort:** S (human: 3h / CC: 15min)  
**Priority:** P1  
**Depends on:** Phase 1  
**Blocked by:** None

### 3. Error Reporting (Sentry)
**What:** Automatic crash reporting with stack traces and breadcrumbs  
**Why:** Cheapest operational insurance — fix crashes before users report them  
**Pros:** Free tier covers 5k errors/month; Mac SDK mature; symbolicated crashes  
**Cons:** ~15 min implementation; DSN is public (by design)  
**Context:** Add `SentrySDK.start()` in app delegate. Upload dSYMs in CI for symbolication.  
**Effort:** S (human: 2h / CC: 10min)  
**Priority:** P1  
**Depends on:** Phase 1  
**Blocked by:** None

### 4. Onboarding Flow
**What:** First-launch animated tutorial showing Command+D shortcut  
**Why:** Users don't discover features; reduces "how do I use this?" support  
**Pros:** High impact on activation; can be skippable; only shows once  
**Cons:** ~20 min implementation; needs design/copy  
**Context:** SwiftUI `sheet` or custom overlay. 3-step tutorial: 1) Welcome, 2) Grant permissions, 3) Try Command+D. Store `hasSeenOnboarding` in UserDefaults.  
**Effort:** S (human: 4h / CC: 20min)  
**Priority:** P2  
**Depends on:** Phase 1  
**Blocked by:** None

## Phase 3: Platform Expansion (Future)

### 5. iOS Companion App
**What:** iPhone/iPad app with 80% code reuse from Mac app  
**Why:** Expand market; cross-device sync; iOS has more users than Mac  
**Pros:** SwiftUI shares code; validates 10x vision  
**Cons:** L effort; requires user accounts + sync; App Store review process  
**Context:** Shared Swift package for core logic. iOS uses same API. Add user accounts (Clerk/Auth0) for sync.  
**Effort:** L (human: 1 week / CC: 2-3 hours)  
**Priority:** P2  
**Depends on:** Mac app validates demand (>100 active users)  
**Blocked by:** Phase 2 operational infrastructure

### 6. Web App (Windows/Linux)
**What:** Browser-based dictionary for non-Mac users  
**Why:** Expand reach; Chromebook, Windows, Linux users  
**Pros:** React/Vue + existing API; reuse server infrastructure  
**Cons:** Can't do global text selection (no Command+D equivalent); M effort  
**Context:** Web app with text input field. Browser extension could do page selection.  
**Effort:** M (human: 3 days / CC: 1 hour)  
**Priority:** P3  
**Depends on:** Phase 2  
**Blocked by:** None

### 7. Chrome Extension
**What:** Browser extension for web page word lookup  
**Why:** Alternative discovery channel; use while reading online  
**Pros:** JavaScript-based; can reuse API; smaller effort than full web app  
**Cons:** Extension store policies; permission warnings scare users  
**Context:** Content script injects lookup button on word selection. Popup for definition.  
**Effort:** M (human: 2 days / CC: 45min)  
**Priority:** P3  
**Depends on:** Phase 2  
**Blocked by:** None

## Phase 4: Business Model (If Demand Validates)

### 8. Premium Subscription
**What:** Freemium model with paid tier for advanced features  
**Why:** Monetization; sustainable business; fund development  
**Pros:** Proven model (Anki, etc.); Stripe integration straightforward  
**Cons:** XL effort; requires user accounts, entitlements, support  
**Context:** Free: 50 lookups/day. Premium ($5/mo): unlimited, advanced AI models, sync, priority support. Use RevenueCat for IAP + Stripe for web.  
**Effort:** XL (human: 2 weeks / CC: 4-6 hours)  
**Priority:** P3  
**Depends on:** >1000 active users, validation that people pay for learning tools  
**Blocked by:** iOS app (for IAP), user accounts, analytics showing retention

### 9. Community Features
**What:** Shared word lists, leaderboards, study groups  
**Why:** Engagement, retention, network effects  
**Pros:** High retention when social; viral growth potential  
**Cons:** Moderation burden; infrastructure cost; L effort  
**Context:** Users create public lists ("GRE Vocab", "Business English"). Others can fork, study. Leaderboards by words learned.  
**Effort:** L (human: 1 week / CC: 2-3 hours)  
**Priority:** P3  
**Depends on:** User accounts, >500 active users  
**Blocked by:** Phase 3

## Technical Debt & Maintenance

### 10. E2E Test Automation
**What:** Automated test for "select text → see definition" critical path  
**Why:** Manual testing doesn't scale; catch regressions before release  
**Pros:** Confidence in shipping; faster release cycles  
**Cons:** XCUITest setup painful; Accessibility permissions in CI tricky  
**Context:** Use XCUITest with test host app. OR use screenshot testing (Snapshot from Fastlane). Start with manual checklist, automate when team grows.  
**Effort:** M (human: 1 day / CC: 1 hour)  
**Priority:** P2  
**Depends on:** Phase 1 stable  
**Blocked by:** None

### 11. API Documentation
**What:** OpenAPI/Swagger spec for server API  
**Why:** Enables third-party integrations; team onboarding  
**Pros:** Auto-generated docs; client SDK generation  
**Cons:** ~30 min to set up; needs maintenance  
**Context:** Use `swagger-jsdoc` or hand-write OpenAPI YAML. Host on GitHub Pages.  
**Effort:** S (human: 2h / CC: 10min)  
**Priority:** P3  
**Depends on:** API stable  
**Blocked by:** None

### 12. Performance Monitoring
**What:** Track API latency, cache hit rates, error rates in dashboard  
**Why:** Proactive performance optimization; catch degradation early  
**Pros:** Operational visibility; data-driven optimization  
**Cons:** Tooling setup (Grafana, etc.); ongoing cost  
**Context:** Fly.io has built-in metrics. Add custom metrics for cache hit rate. Use PostHog for product metrics, separate tool for infra.  
**Effort:** S (human: 3h / CC: 15min)  
**Priority:** P2  
**Depends on:** Phase 2  
**Blocked by:** None

## Deferred from CEO Review (Skipped)

- Keyboard-only navigation mode — power user feature, low demand
- Anki/Quizlet export — bridge to spaced repetition, low priority
- Enterprise/SSO — requires sales motion, out of scope
- Multi-region server deployment — premature optimization

---

**Last updated:** 2026-03-20 by /plan-eng-review  
**Next review:** After Phase 1 ships
