# WayPoint Super Good Execution Plan

This document is the working plan for turning WayPoint from a promising rail app into a daily-use product people trust. It is intentionally detailed. The point is to make each improvement executable, testable, and tied to the existing codebase rather than floating around as product fog.

## North Star

WayPoint should answer one question faster than any other app:

> What train should I take, how bad is the service right now, and what should I do next?

The app should feel like a reliable travel companion, not a catalog of rail networks. Breadth matters later. The first version that feels excellent should be deep in one or two real markets, honest about data coverage, fast for repeat journeys, and calm under disruption.

## Product Principles

1. Speed beats breadth.
   The first screen should solve the most common repeat journey with as little input as possible.

2. Trust beats spectacle.
   Every live result needs freshness, source, and stale-data behavior. Fake-looking "live" content is worse than no live content.

3. Commuters are the primary audience.
   Optimize for repeated routes, habitual times, saved stations, reverse journeys, and disruption awareness.

4. Official data first.
   Prefer official feeds and clearly label preview/fallback data. Do not silently mix mock data into live surfaces.

5. One excellent market before many shallow markets.
   UK Rail plus London Underground is the obvious flagship because the current app already has Huxley2 National Rail, TfL, station search, and route planning foundations.

6. The UI should be calm, dense, and scannable.
   This is a transport utility. It should feel premium through clarity, not decorative complexity.

## Current App Snapshot

The app currently has:

- A SwiftUI tab shell in `WayPoint/App/AppShellView.swift`.
- A train times flow in `WayPoint/Features/Times/TrainTimesView.swift`.
- Trip cards and service details in `WayPoint/Features/Times/TripCard.swift`.
- Station search and departure orchestration in `WayPoint/Services/SearchViewModel.swift`.
- Huxley2 National Rail integration in `WayPoint/Services/DepartureService.swift`.
- A static/local station repository in `WayPoint/Services/StationRepository.swift`.
- A large network catalog in `WayPoint/Models/RailNetwork.swift`.
- A live rail map surface in `WayPoint/Features/Map/LiveMapView.swift`.
- A metro/subway planner in `WayPoint/Features/Map/SubwayMapView.swift`.
- TfL and MTA live service integration in `WayPoint/Services/MetroLiveService.swift`.
- A custom MTA GTFS realtime parser in `WayPoint/Services/MTAGTFSRealtime.swift`.

Major strengths:

- The product shape is already real: times, maps, metro, location detection, live integrations.
- The app has a coherent visual language.
- SwiftUI Observation is already in use.
- The UK/London data path is close enough to become the flagship.

Major risks:

- Some "live map" content is sample data embedded in `RailNetwork.trains`.
- The first screen is still generic instead of personal.
- Saved routes, recents, alerting, and active journey tracking do not exist yet.
- Provider concerns are mixed into giant enums.
- There are no visible test targets in the current project tree.

## Execution Overview

The work should happen in phases:

1. Commuter foundation.
   Add saved routes, recent searches, one-tap search, reverse route, and a better first screen.

2. Trust layer.
   Add data freshness, provider labels, stale-state warnings, and refresh behavior to all live surfaces.

3. Trip quality.
   Improve trip cards with best/fastest/risk labels, stronger platform display, disruption reasons, and trackable journeys.

4. Active journey and alerts.
   Add tracking, local notifications, Live Activity, and platform/delay/cancellation monitoring.

5. Provider architecture.
   Split rail and metro providers into capability-driven adapters with normalized models.

6. Market depth.
   Make UK Rail + London Underground feel complete before expanding more networks.

7. Test and release readiness.
   Add unit tests, UI smoke tests, offline states, accessibility checks, privacy strings, and App Store readiness.

## Execution Log

### 2026-07-03

Completed the first trust layer slice (Phase 2):

- Added `LiveDataSnapshot` freshness/provenance metadata and a `DepartureBoardSnapshot` wrapper.
- `DepartureService.fetchDepartures` now returns trips plus metadata ("National Rail via Huxley2", 2-minute TTL).
- `SearchViewModel` keeps the previous board on a failed same-route refresh, re-labeled as fallback, instead of blanking results.
- Added a shared `LiveFreshnessRow` component: updated time, source label, refresh button, and stale/fallback warnings.
- Applied it to the Times departures list and the metro Lines section.
- `SubwayMapView` tracks live feed metadata per system (`MetroSystem.liveSourceName`) and keeps last-good statuses/arrivals on refresh errors.
- Removed stray duplicate " 2" files left by a file sync.
- Added pull-to-refresh on the Times tab and an updated/source footer on the service detail sheet.
- Added a "Preview data" warning banner on the Live Map so sample train positions are never presented as live.
- Fixed a real TfL arrivals bug found during verification: the decoder required fields TfL sometimes omits (destinationName etc.), which silently killed the whole live refresh. Decoding is now tolerant, and line statuses/arrivals fail independently.
- Added a DEBUG-only launch-environment harness for automated simulator verification: WAYPOINT_DEBUG_TAB (initial tab), WAYPOINT_DEBUG_AUTOSEARCH ("EUS>MAN"), WAYPOINT_DEBUG_SCROLL (lines/arrivals). Pass via SIMCTL_CHILD_* with simctl launch.
- Verified end-to-end in the iOS Simulator (iPhone 17 Pro + iPad Pro 13): live Euston-Manchester departures with freshness row, stale state appearing after the 2-minute TTL, TfL line statuses with "Updated just now / TfL Unified API", real arrival predictions, and the Live Map preview banner.

Phase 2 acceptance criteria are met on the Times, Underground, and Live Map surfaces.

Also completed the first trip quality slice (Phase 3):

- Added deterministic ranking badges (`TripRanking.swift`): Best = arrives first, Fastest = shortest journey (only when 2+ services are running and Best doesn't already cover it), plus Delayed and Cancelled. Each badge has an explanation used as its accessibility label.
- Upgraded `TripCard`: badge row, prominent platform pill near the times ("Platform pending" when unknown), cancelled trips shown with strikethrough times, delay/cancel reasons on their own unclamped line, and an inline "Calls at X, Y, Z +n more" preview of intermediate stops.
- Verified in the simulator against live Euston-Manchester data (Best badge, Platform A pill, calling point preview all rendering).

Still open in Phase 3: "Least risky" tag (needs a reliability heuristic), highlighted skipped/cancelled stops, and the track/save/reverse/official-source actions on cards.

### 2026-05-22

Completed the first commuter foundation slice:

- Added persistent saved/recent route models.
- Added a `RouteStore` backed by `UserDefaults`.
- Added route selection handoff methods to `SearchViewModel`.
- Added a commuter board above the manual search form.
- Recorded successful searches as recent routes.
- Added one-tap rerun, reverse, save, and unsave actions.
- Verified with an iOS Simulator build.

## Phase 1: Commuter Foundation

### Goal

Make the Times tab immediately useful before the user types anything.

### User Experience

When the user opens the Times tab, they should see:

- A short, personal header.
- A "Commuter board" with saved routes and recent searches.
- One-tap chips for common routes.
- A reverse button for saved/recent routes.
- A "Use last search" affordance if no saved route exists.
- The existing manual search form below the commuter board.

### Data Model

Create a route model that can be persisted:

- `SavedRoute`
  - `id`
  - `originName`
  - `originCode`
  - `destinationName`
  - `destinationCode`
  - `networkID`
  - `nickname`
  - `createdAt`
  - `lastUsedAt`
  - `isFavorite`

For optional destination searches, allow destination fields to be empty.

### Storage

Use `UserDefaults` with JSON encoding for the first pass:

- Low risk.
- No schema migration needed yet.
- Easy to replace later with SwiftData.

Create a small `RouteStore` service:

- `savedRoutes`
- `recentRoutes`
- `addFavorite(origin:destination:network:)`
- `recordSearch(origin:destination:network:)`
- `removeFavorite(_:)`
- `promoteRecentToFavorite(_:)`
- `touch(_:)`

### UI Work

Add a commuter board inside `TrainTimesView` above the search card:

- Show favorites first.
- Show recents if there are no favorites or underneath favorites.
- Each route row should display:
  - origin -> destination
  - network short label
  - last used text
  - favorite icon state
  - search button
  - reverse button

Add save behavior:

- After a successful search, record the route as recent.
- Provide a "Save route" action for searches with known station codes.
- Avoid saving unknown freeform station text.

### Implementation Files

Add:

- `WayPoint/Models/SavedRoute.swift`
- `WayPoint/Services/RouteStore.swift`

Modify:

- `WayPoint/Services/SearchViewModel.swift`
- `WayPoint/Features/Times/TrainTimesView.swift`
- potentially `WayPoint/Components/RouteField.swift`

### Acceptance Criteria

- User can run a search and see it appear in recent routes.
- User can tap a recent route to populate fields and search.
- User can reverse a route and search.
- User can favorite the current known route.
- Favorites persist across app launches.
- Recents persist across app launches.
- Empty destination station searches still work.
- Network switching does not incorrectly keep routes from a different network in the active board.

## Phase 2: Trust Layer

### Goal

Make live data feel reliable and honest.

### Add Metadata

Create normalized metadata:

- `LiveDataSnapshot`
  - `sourceName`
  - `sourceURL`
  - `fetchedAt`
  - `expiresAt`
  - `isStale`
  - `isFallback`

### Apply To

- National Rail departure results.
- Service detail sheets.
- TfL line status.
- MTA line status.
- Metro arrivals.
- Live map data.

### UI Requirements

Every live surface should show:

- "Updated 7:42 PM"
- Source label such as "National Rail via Huxley2"
- Pull to refresh or a refresh button.
- Stale warning if data is older than the expected TTL.
- Clear copy when provider is unavailable.

### Implementation Notes

The current `DepartureService.fetchDepartures` returns `[RailTrip]`. It should eventually return a wrapper:

- `DepartureBoardSnapshot`
  - `trips`
  - `metadata`
  - `origin`
  - `destination`

Do this carefully because `SearchViewModel`, `TrainTimesView`, and `TripCard` all assume plain trips.

### Acceptance Criteria

- Users can tell when results were fetched.
- Stale results look visually different.
- Error states do not wipe useful previous data unless the user explicitly changes route.
- Sample data is never labeled as live.

## Phase 3: Trip Quality

### Goal

Make each departure card instantly scannable.

### Improvements

- Add ranking tags:
  - Best
  - Fastest
  - Least risky
  - Direct
  - Delayed
  - Cancelled

- Upgrade platform display:
  - Large pill near departure time.
  - "Platform pending" if unknown.

- Improve delay display:
  - Use status color.
  - Show reason on second line when present.
  - Avoid one-line truncation for important disruption reasons.

- Improve calling points:
  - Show first few stops inline.
  - Keep full list in detail sheet.
  - Highlight skipped/cancelled stops when provider data supports it.

- Add route actions:
  - Track this train.
  - Save route.
  - Reverse route.
  - Open official source.

### Acceptance Criteria

- A delayed or cancelled train is obvious within one second.
- Platform is visible without opening the detail sheet.
- Best/fastest/risk tags are deterministic and explainable.

## Phase 4: Active Journey And Alerts

### Goal

Turn search results into journey monitoring.

### Features

- Track a selected train.
- Poll or refresh provider data at sensible intervals.
- Notify for:
  - cancellation
  - platform change
  - delay over threshold
  - train approaching departure
  - changed destination/short running where provider exposes it

### iOS Capabilities

- Local notifications.
- Background refresh, if feasible.
- Live Activities and Dynamic Island for active journeys.

### Data Model

- `TrackedJourney`
  - selected service id
  - route
  - departure time
  - arrival time
  - platform
  - current status
  - last fetched snapshot
  - notification preferences

### Acceptance Criteria

- User can track a train from a trip card.
- App remembers the active journey.
- Notifications are permission-gated and useful.
- The app never over-notifies.

## Phase 5: Provider Architecture

### Goal

Make adding markets a controlled engineering task rather than editing giant enums.

### New Protocols

Create protocols:

- `RailDepartureProvider`
  - capabilities
  - station search
  - departures
  - service detail
  - disruptions

- `MetroProvider`
  - capabilities
  - network map
  - line statuses
  - arrivals
  - route planning support

- `ProviderCapabilities`
  - liveDepartures
  - serviceDetails
  - liveVehicles
  - disruptions
  - officialMap
  - stationSearch
  - fares
  - bookingURL

### Migration Path

1. Wrap the existing Huxley2 code as `NationalRailProvider`.
2. Wrap TfL code as `TfLMetroProvider`.
3. Wrap MTA code as `MTAMetroProvider`.
4. Keep `RailNetwork` as catalog metadata only.
5. Move sample train data out of `RailNetwork`.

### Acceptance Criteria

- Adding a new provider does not require editing UI logic.
- UI renders based on capabilities.
- Fallback data is explicitly typed as fallback.

## Phase 6: Market Depth

### UK Rail

Add:

- Better station corpus.
- Better CRS resolution.
- Common aliases, such as "Kings Cross" and "King's Cross".
- Service detail refresh.
- Disruption board.
- Operator branding where appropriate.
- Booking handoff with selected journey context if possible.

### London Underground

Add:

- Full network map rather than partial fallback.
- Line disruptions with official reasons.
- Arrival predictions by selected station.
- Cross-surface route planning: National Rail station to Tube station.

### Acceptance Criteria

- UK/London feels complete enough to demo as the main product.
- "Coming soon" surfaces are secondary, not the core experience.

## Phase 7: Testing And Release Readiness

### Unit Tests

Add tests for:

- `StationRepository.search`.
- `StationRepository.resolveStation`.
- `DepartureService` URL construction.
- Huxley response mapping.
- `MetroRoutePlanner.fastestRoute`.
- MTA realtime parser using sample protobuf fixtures.
- Route persistence.

### UI Smoke Tests

Add tests for:

- Launch.
- Times tab search flow.
- Route saving.
- Metro route planner.
- Network switching.

### Accessibility

Verify:

- Dynamic Type.
- VoiceOver labels.
- Button hit targets.
- Reduced motion behavior.
- Color contrast in light and dark mode.

### Privacy And Permissions

Verify:

- Location usage string.
- Notification usage path.
- No hidden tracking.
- Clear explanation for location and notifications.

## First Execution Slice

The first slice to implement is:

1. Done: Add persistent route models and route store.
2. Done: Add a commuter board to `TrainTimesView`.
3. Done: Record successful searches as recents.
4. Done: Allow recent routes to be rerun.
5. Done: Allow current route to be saved as a favorite.
6. Done: Allow favorite/recent routes to be reversed.

This slice is valuable because it changes the app from "type a journey every time" to "open and go."

## Later Backlog

- Home screen widgets for saved routes.
- Siri/App Shortcuts for "next train home".
- Lock screen Live Activity.
- Calendar-aware suggested journeys.
- Delay history and reliability scoring.
- Fare comparison where official data allows it.
- Offline favorite route shell.
- Real live vehicle feeds only where official feed quality is acceptable.
- Operator-specific disruption copy cleanup.
- Full data-provider health diagnostics.
