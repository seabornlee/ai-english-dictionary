# Design System — AI Dictionary

## Product Context
- **What this is:** A macOS application that helps users learn and understand English words through pure English explanations, without relying on translations. Features global text selection with Command+D shortcut, AI-powered definitions, and vocabulary management.
- **Who it's for:** English learners who want to build pure English thinking and avoid translation dependency. Users who value seamless workflow integration.
- **Space/industry:** Language learning tools, direct-download Mac utilities
- **Project type:** Native macOS SwiftUI app + single-page marketing site
- **Distribution:** Direct download (DMG), not Mac App Store — preserves global text selection capabilities

## Aesthetic Direction
- **Direction:** Editorial/Refined — The Learning Companion
- **Decoration level:** Intentional — subtle texture on landing page, native cleanliness in app
- **Mood:** Quiet, thoughtful, respectful of the user's intelligence. Like a well-designed notebook on a scholar's desk — warm, intentional, uncluttered. Signals "this takes your learning seriously."

**Why this aesthetic:** The core value is "learn without translations" — a thoughtful, intentional act. Generic utility styling would undermine this positioning.

## Typography

### Font Families
- **Display/Hero:** Newsreader (Google Fonts) — editorial, literary, signals "this is for reading and learning"
- **Body:** Source Serif 4 (Google Fonts) — excellent readability for definitions and longer text
- **UI/Labels:** System San Francisco — native macOS, no custom font needed
- **Data/Tables:** System San Francisco with `tabular-nums` enabled
- **Code:** System San Francisco Mono or JetBrains Mono

### Type Scale
| Level | Size | Usage |
|-------|------|-------|
| Hero | 48px/3rem | Landing page headline |
| H1 | 36px/2.25rem | App title, major headings |
| H2 | 28px/1.75rem | Section titles |
| H3 | 24px/1.5rem | Card titles, word terms |
| H4 | 20px/1.25rem | Subsection headings |
| Body Large | 18px/1.125rem | Featured paragraphs |
| Body | 16px/1rem | Default body text |
| Small | 14px/0.875rem | Labels, captions |
| Tiny | 12px/0.75rem | Timestamps, metadata |

### Typography Rules
- Line-height: 1.6 for body, 1.2 for display
- Measure: 45-75 characters per line (66 ideal)
- No letter-spacing on lowercase body text
- Use `text-wrap: balance` for headings when supported
- Curly quotes (", '") not straight quotes

## Color

### Approach
Restrained + Warm — Forest green as primary differentiator from typical blue "tech" colors.

### Palette

#### Primary
| Name | Hex | Usage |
|------|-----|-------|
| Forest Green | `#2C5F2D` | Primary buttons, active states, success |
| Forest Hover | `#3A7A3B` | Button hover states |
| Sage | `#97BC62` | Secondary accents, word chip hover |

#### Neutrals (Warm Gray Family)
| Name | Hex | Usage |
|------|-----|-------|
| Paper | `#F8F6F3` | Page background |
| Warm 100 | `#E8E4DF` | Card backgrounds, borders |
| Warm 200 | `#D4CFC8` | Dividers, disabled states |
| Warm 500 | `#9A9590` | Muted text, placeholders |
| Warm 700 | `#6B6763` | Secondary text |
| Warm 900 | `#4A4744` | Primary text, headings |

#### Semantic
| Name | Hex | Usage |
|------|-----|-------|
| Success | `#2C5F2D` | Same as primary |
| Error | `#B54A4A` | Error states, destructive actions |
| Warning | `#C9A227` | Warnings, caution |
| Info | `#4A7C9B` | Informational states |

### Dark Mode
| Name | Hex | Usage |
|------|-----|-------|
| Dark BG | `#1C1B1A` | Deepest background |
| Dark Surface | `#252422` | Card backgrounds |
| Dark Elevated | `#2E2C2A` | Elevated surfaces |
| Dark Text | `#E8E6E3` | Primary text (off-white, not pure) |
| Dark Text Secondary | `#B8B5B2` | Secondary text |

**Dark mode adjustments:**
- Primary desaturates 10-20% to `#3A7A3B`
- Surfaces use layered depth, not just lightness inversion
- Text is off-white, never pure white

### Color Usage Rules
- Primary green for CTAs, active states, and key actions
- Warm neutrals for structure (borders, backgrounds)
- Max 12 unique non-gray colors total
- Never rely on color alone — always pair with icons or labels
- Ensure 4.5:1 contrast for body text, 3:1 for large text and UI

## Spacing

### Base Unit
**4px** — all spacing values derive from this

### Scale
| Token | Value | Usage |
|-------|-------|-------|
| space-1 | 4px | Tight internal padding |
| space-2 | 8px | Inline spacing, small gaps |
| space-3 | 12px | Compact padding |
| space-4 | 16px | Default padding, comfortable gaps |
| space-6 | 24px | Section padding, card padding |
| space-8 | 32px | Large gaps, major sections |
| space-12 | 48px | Section breaks, hero padding |
| space-16 | 64px | Major section separations |
| space-24 | 96px | Landing page section breaks |

### Spacing Rules
- Use the scale — no arbitrary values
- Related items closer together, distinct sections further apart
- App: comfortable density (20-32px padding)
- Landing: generous whitespace (48-64px padding)

## Layout

### Approach
Grid-disciplined for app, editorial for landing

### App Layout (macOS Native)
- **Window:** Min 800x600, resizable
- **Structure:** Three-column NavigationView
  - Sidebar: 200px min-width, 4 navigation items
  - Main content: Flexible
  - Detail (when applicable): Flexible
- **Spacing:** System SwiftUI defaults with 16-20px section padding

### Landing Page Layout
- **Hero:** Left-aligned, generous top padding (96px+)
- **Content max-width:** 1200px centered
- **Grid:** CSS Grid with asymmetric editorial feel
- **Responsive:** 
  - Desktop (1024px+): Full layout
  - Tablet (768-1023px): Adjusted spacing, maintained hierarchy
  - Mobile (<768px): Single column, stacked sections

### Border Radius Hierarchy
| Element | Radius | Example |
|---------|--------|---------|
| Small (buttons, inputs) | 6-8px | `.btn`, `.input` |
| Medium (cards) | 12px | `.card`, `.feature-card` |
| Large (modals, sheets) | 16px | `.modal`, `.floating-window` |
| Full (pills, badges) | 9999px | `.pill`, `.badge` |

**Inner radius rule:** Nested element radius = parent radius - gap

## Motion

### Approach
Intentional — every animation serves a purpose

### Easing
- **Default:** `cubic-bezier(0.25, 0.1, 0.25, 1.0)` — smooth, natural
- **Enter:** `ease-out` — quick start, gentle settle
- **Exit:** `ease-in` — gentle start, quick finish
- **Move:** `ease-in-out` — balanced

### Duration
| Type | Duration | Usage |
|------|----------|-------|
| Micro | 150ms | Button presses, color changes |
| Fast | 200ms | Hover states, small transitions |
| Normal | 300ms | State changes, reveals |
| Slow | 400ms | Page transitions, major reveals |

### Specific Motions
- **Word marking:** Scale 1.0 → 1.05 → 1.0 + color transition (200ms)
- **Floating window:** Fade in + slight scale from cursor origin (300ms)
- **Definition regeneration:** Crossfade with loading spinner (300ms)
- **Page transitions:** Fade with subtle slide (400ms)

### Accessibility
- Always respect `prefers-reduced-motion`
- No decorative animations that don't serve a purpose
- Only animate `transform` and `opacity` — never layout properties

## Components

### Buttons

**Primary Button**
- Background: Forest green `#2C5F2D`
- Text: White
- Padding: 12px 24px
- Border-radius: 8px
- Font: System UI, 500 weight
- Hover: `#3A7A3B`, subtle lift (`translateY(-1px)`)
- Active: Scale 0.98

**Secondary Button**
- Background: Warm 100 `#E8E4DF`
- Text: Warm 900 `#4A4744`
- Same sizing as primary
- Hover: Warm 200 `#D4CFC8`

**Ghost Button**
- Background: Transparent
- Border: 1px solid Warm 200
- Text: Primary green
- Hover: Warm 100 background

### Inputs

**Text Input**
- Border: 1px solid Warm 200
- Border-radius: 8px
- Padding: 12px 16px
- Font: Body serif, 16px
- Focus: Border color Primary green, no outline
- Background: White (Paper in dark mode)

### Cards

**Feature Card**
- Background: White
- Border: 1px solid Warm 200
- Border-radius: 12px
- Padding: 32px
- Shadow: None (or very subtle `0 2px 8px rgba(0,0,0,0.04)`)

### Word Chips
- Background: Warm 100
- Border-radius: 6px
- Padding: 6px 12px
- Font: Body, 15px
- Hover: Sage green background, white text
- Marked state: Forest green background, white text

## Platform-Specific Notes

### macOS App
- Follow macOS Human Interface Guidelines
- Use native SwiftUI components where possible
- Respect system appearance (light/dark mode)
- Support system font size settings
- Menu bar icon: Simple, recognizable at 16px
- Floating window: Native NSWindow with `.floating` level

### Landing Page
- Semantic HTML for accessibility
- Keyboard navigable
- WCAG 2.1 AA compliance
- Responsive images with srcset
- System fonts for UI text (better performance)

## AI Slop Avoidance

### Never Use
- Purple/violet/indigo gradients
- 3-column feature grids with icons in colored circles
- Centered everything with uniform spacing
- Uniform bubbly border-radius on all elements
- Decorative blobs or wavy dividers
- Emoji as design elements
- Generic hero copy ("Welcome to X", "Unlock the power")

### Instead
- Asymmetric editorial layouts
- Purposeful whitespace
- Serif typography as differentiator
- Forest green as unexpected primary
- Specific, concrete copy

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-20 | Initial design system created | Created by /design-consultation based on CEO plan, design review outcomes, and direct-download Mac app research |
| 2026-03-20 | Serif typography (Newsreader + Source Serif 4) | Differentiates from utility apps, reinforces "learning companion" positioning |
| 2026-03-20 | Forest green primary | Unexpected in category, growth metaphor, warm alternative to blue |
| 2026-03-20 | Warm gray neutral family | Human, approachable, cohesive with green |
| 2026-03-20 | Editorial layout for landing | Breaks from SaaS conventions, signals thoughtful product |
| 2026-03-20 | Philosophy-first messaging | "Learn without translations" before "Command+D" feature |

## Files to Reference

- CEO Plan: `~/.gstack/projects/seabornlee-ai-english-dictionary/ceo-plans/2026-03-20-ship-ai-dictionary.md`
- Design Review: `~/.gstack/projects/seabornlee-ai-english-dictionary/main-reviews.jsonl`

## Next Steps

1. **Implement landing page** using this design system
2. **Verify macOS app** conforms to system (already native SwiftUI)
3. **Create component library** in code (SwiftUI views, CSS components)
4. **Generate assets** — app icon, OG images, screenshots in both themes
5. **Accessibility audit** — test with VoiceOver, keyboard navigation, color contrast
6. **Consider DESIGN.md v2** after launch with real user feedback
