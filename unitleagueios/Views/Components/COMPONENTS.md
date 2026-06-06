# Components

Reusable views used across the app's tab structure. Each file ends with a `#Preview` block using mock data from `PreviewMocks.swift`.

---

## ViewTeamBanner

**Purpose:** Reusable team header card — gradient background, sport icon, team name, conference/division/mascot metadata.

**Models:** `Team`, `League`

**Data source:** Passed in by parent — no network calls.

**Used in:**
- `ViewTeamList` (team list row, `showChevron: true`)
- `ViewSched` (schedule header)
- `ViewGameDetail` (away and home team links)

**Sub-components:** `TeamMetaRow` (private)

**Environment:** `AppTheme`

---

## ViewSched

**Purpose:** Full-screen team schedule — year/recent mode filter, game-by-game results, highlights the last completed game.

**Models:** `Team`, `League`, `Sched`

**Data source:** `SchedService.fetchSchedule(teamId:yr:)` on `.task`.

**Used in:**
- `ViewTeamList` (NavigationLink destination)
- `ViewGameDetail` (away and home team links)

**Sub-components:** `ViewTeamBanner`, `FilterChip`, `SchedCard` (private)

**Environment:** `AppTheme`

---

## ViewTeamList

**Purpose:** Browseable list of all teams in a league with conference/division filter chips.

**Models:** `Team`, `League`

**Data source:** `TeamService.fetchTeams(leagueId:)` on `.task`.

**Used in:**
- `TabResearchView` (one instance per selected league)

**Sub-components:** `ViewTeamBanner`, `FilterChip`, `ViewSched` (NavigationLink destination)

**Environment:** `AppTheme`

---

## ViewGameDetail

**Purpose:** Full game detail — best odds table (`GameOddsCard`), all-book odds expansion (`AllOddsSection`), team links, bet selection.

**Models:** `Odds`, `OddMany`, `Team`, `League`, `SelectedBet`

**Data source:** `OddsService`, `OddManyService`, `TeamService`, `LeagueService` — all fetched in parallel on `.task`.

**Used in:**
- `TabBetsView` (primary odds browsing destination)

**Sub-components:** `BetGameBanner`, `GameOddsCard`, `AllOddsSection` (private), `ViewTeamBanner`, `ViewSched` (NavigationLink), `SheetConfirmBet`

**Environment:** `AppTheme`, `BetStore`, `@AppStorage("bettorId")`, `@AppStorage("selectedSyndicateId")`

---

## ViewSyndicate

**Purpose:** Syndicate detail page — member leaderboard ranked by unit balance, admin edit access, select/deselect as active syndicate.

**Models:** `Syndicate`, `Runner`

**Data source:** `RunnerService.fetchRunner(syndicateId:)` on `.task`. `Syndicate` is passed in by parent.

**Used in:**
- `TabSyndicateView` (NavigationLink destination from syndicate list)

**Sub-components:** `RunnerRow` (private), `EditSyndicateSheet` (private sheet)

**Environment:** `AppTheme`, `@AppStorage("bettorId")`, `@AppStorage("selectedSyndicateId")`, `@AppStorage("leagueSymbol")`, `@AppStorage("leagueColorName")`, `@AppStorage("leagueRank")`

---

## SheetConfirmBet

**Purpose:** Bet placement modal for a single straight bet — wager unit stepper, syndicate + runner identity display, bookmark or submit.

**Models:** `SelectedBet`, `Runner`, `Syndicate`, `PlacedBet`

**Data source:** `RunnerService`, `SyndicateService` on `.task`. `SelectedBet` passed in by parent.

**Used in:**
- `ViewGameDetail` (sheet on bet tap)
- `SheetBookmarks` (sheet on bookmarked bet tap)
- `TabBetsView`

**Sub-components:** `BetGameBanner`, `SheetSyndicateSelector`, `SheetConfirmParlay`

**Environment:** `AppTheme`, `BetStore`, `@AppStorage("unitBalance")`

---

## SheetConfirmParlay

**Purpose:** Parlay placement modal — shows all bookmarked legs (or builds from a current bet), leg selection toggles, combined odds, wager stepper, submit.

**Models:** `SelectedBet?` (optional seed), `PlacedBet` (legs), `Runner`, `Syndicate`

**Data source:** `BetStore` for existing bookmarks; `RunnerService`, `SyndicateService` on `.task`. Optionally accepts `savedLegs: [PlacedBet]` pre-populated from bookmarks.

**Used in:**
- `SheetConfirmBet` (Add to Parlay action)
- `SheetBookmarks` (Parlay toolbar button and bookmarked parlay tap)

**Sub-components:** `BetGameBanner`, `SheetSyndicateSelector`

**Environment:** `AppTheme`, `BetStore`, `@AppStorage("unitBalance")`

---

## SheetBookmarks

**Purpose:** Bookmarks list modal — straight bets and parlay groups saved locally, with remove and place actions.

**Models:** `PlacedBet`

**Data source:** `BetStore` (local `UserDefaults`-backed). No network calls.

**Used in:**
- `SharedToolbar` (bookmarks button)
- `TabBetsView` (bookmarks button)

**Sub-components:** `SheetConfirmBet`, `SheetConfirmParlay`

**Environment:** `AppTheme`, `BetStore`, `@AppStorage("bettorId")`, `@AppStorage("selectedSyndicateId")`

---

## SheetSyndicateSelector

**Purpose:** Syndicate picker modal — lists the user's syndicates, sets the active syndicate in `@AppStorage`.

**Models:** `Syndicate`

**Data source:** `SyndicateService.fetchSyndicate(bettorId:)` on `.task`. Skips fetch when `bettorId == 0`.

**Used in:**
- `SharedToolbar` (active syndicate selector)
- `SheetConfirmBet` (syndicate selection before placing)
- `SheetConfirmParlay` (syndicate selection before placing)

**Sub-components:** None

**Environment:** `AppTheme`

**Bindings required:** `selectedSyndicateId`, `leagueSymbol`, `leagueColorName`, `leagueRank`

---

## SheetCreateSyndicate

**Purpose:** New syndicate creation form — name, description, privacy toggle, max runners, symbol and color pickers.

**Models:** `AccentOption`, `SyndicateOption`

**Data source:** `SyndicateService.createSyndicate(...)` on submit. No initial fetch.

**Used in:**
- `TabSyndicateView` (Create button)

**Sub-components:** None

**Environment:** `AppTheme`

---

## SheetEditProfile

**Purpose:** Profile editing modal — custom display name, profile symbol, accent color; Apple ID sign-in link.

**Models:** `AccentOption`, `ProfileOption`

**Data source:** `BettorService.updateProfile(...)` on submit. Profile values read/written via `@AppStorage`.

**Used in:**
- `TabProfileView` (Edit button)

**Sub-components:** None

**Environment:** `AppTheme`, `@AppStorage("appleUserName")`, `@AppStorage("customUserName")`, `@AppStorage("profileSymbol")`, `@AppStorage("profileSaved")`

---

## SheetJoinSyndicate

**Purpose:** Join-syndicate form — code entry + optional password, submits via `SyndicateService.joinSyndicate`.

**Models:** None (form-only)

**Data source:** `SyndicateService.joinSyndicate(bettorId:code:password:)` on submit.

**Used in:**
- `TabSyndicateView` (Join button)

**Sub-components:** None

**Environment:** `AppTheme`

---

## Shared dependencies

| Dependency | Purpose |
|---|---|
| `AppTheme` | Colors, fonts, backgrounds — required by every component |
| `BetStore` | Local bookmark storage — required by bet sheet components |
| `FilterChip` | Pill-shaped toggle chip — used in `ViewSched`, `ViewTeamList` |
| `BetGameBanner` | Bet detail header row — used in `SheetConfirmBet`, `SheetConfirmParlay`, `ViewGameDetail` |
| `GameOddsCard` | Best-odds table for a game — used in `ViewGameDetail` |
| `ProfileOption` | Color/symbol helpers for bettor profiles — used in `ViewSyndicate`, `SheetSyndicateSelector` |
| `AccentOption` | Named accent color enum — used in syndicate and profile sheets |

---

## Mock data (`PreviewMocks.swift`)

All preview mock data lives in `PreviewMocks.swift` inside a `#if DEBUG` block. It is stripped from release builds.

| Name | Type | Description |
|---|---|---|
| `Mock.leagueNBA` | `League` | NBA (id 1) |
| `Mock.leagueNFL` | `League` | NFL (id 2) |
| `Mock.teamLAL` | `Team` | Lakers — Purple, West/Pacific |
| `Mock.teamBOS` | `Team` | Celtics — Green, East/Atlantic |
| `Mock.teamGSW` | `Team` | Warriors — Gold, West/Pacific |
| `Mock.teamsNBA` | `[Team]` | LAL, BOS, GSW |
| `Mock.syndicate` | `Syndicate` | "Sharp Unit" — public, Green |
| `Mock.syndicate2` | `Syndicate` | "The Books" — private, Blue |
| `Mock.syndicates` | `[Syndicate]` | Both syndicates |
| `Mock.runnerAdmin` | `Runner` | bettorId 42, 250 balance, admin role |
| `Mock.runnerMember` | `Runner` | bettorId 77, 180 balance, member role |
| `Mock.runners` | `[Runner]` | Both runners |
| `Mock.selectedBetML` | `SelectedBet` | BOS @ LAL, ML, Away, 2.10 |
| `Mock.selectedBetSPR` | `SelectedBet` | BOS @ LAL, SPR, Away +5.5, 1.91 |
| `Mock.selectedBetOU` | `SelectedBet` | BOS @ LAL, O/U, Over 224.5, 1.91 |
| `Mock.placedBetML` | `PlacedBet` | Bookmarked ML, 2 units |
| `Mock.placedBetSPR` | `PlacedBet` | Bookmarked SPR, 1 unit |
| `Mock.parlayLegs` | `[PlacedBet]` | 2-leg parlay (ML + SPR) with shared `parlayGroupId` |
| `Mock.odds` | `Odds` | BOS @ LAL gameId 101 — full ML/SPR/O/U odds set |
| `Mock.oddMany` | `[OddMany]` | 3 individual book odds for the same game |
| `Mock.schedItems` | `[Sched]` | 3 LAL schedule entries (1 win, 1 upcoming, 1 loss) |

To extend mock data, add new `static let` or `static var` properties to `enum Mock` inside `PreviewMocks.swift`. Use `#if DEBUG` extensions for any model that lacks a memberwise init (currently `Syndicate`).

---

## Adding a new component

1. Create the Swift file in `Views/Components/`.
2. Add a `#Preview("<ComponentName>")` block at the bottom of the file using `Mock.*` values.
3. If the component needs new model data not already in `PreviewMocks.swift`, add it there.
4. Add an entry to this README covering purpose, models, data source, parent usage, sub-components, and environment dependencies.
