# SaveAMeal — Project Overview

> Synthesized from: `SaveAMeal_Architecture.docx`, `SaveAMeal_Concept & Func.docx`, `SaveAMeal_WBS.docx`, `SaveAMeal_Personas_and_Journey_Maps.docx`
> Generated: 2026-06-02

---

## 1. Project Identity

| Field | Value |
|---|---|
| Name | SaveAMeal |
| Tagline | "Every meal counts. Every minute matters." |
| Platform | Cross-platform Flutter mobile app (iOS, Android, Web) |
| Target market | Bangkok pilot → Southeast Asia |
| One-liner | Real-time food rescue logistics platform — crowdsourced volunteers connect commercial food donors with communities in need, automating what NGOs do manually. |

---

## 2. Problem & Motivation

- **Global**: 1.3B tons of food wasted yearly (~30% of all food produced).
- **Local**: Thailand wastes ~17M tons/year while 5.3M Thais face food insecurity.
- **Environmental**: Food waste = 8–10% of global GHG emissions.
- **NGO gap**: Manual coordination, limited drivers, paper tracking, no real-time matching — scale linearly with staff.
- **SaveAMeal's answer**: Replace the NGO coordination layer with a self-coordinating logistics network (think Grab for food rescue).

---

## 3. The Three-Sided Marketplace

| Role | Who | Brings | Gets |
|---|---|---|---|
| **Donors** (Supply) | Hotels, supermarkets, bakeries, restaurants | Surplus food | Easy disposal, CSR/ESG reporting, tax-incentive docs |
| **Volunteers/Drivers** (Logistics) | Crowdsourced — motorbike, car, bicycle riders | Time & transport | Flexible volunteering, gamified recognition |
| **Beneficiaries** (Demand) | Shelters, orphanages, community kitchens | Distribution capacity & verified need | Reliable food supply matched to daily demand |

**Key insight**: The platform handles only *data* (cheap, scalable). People handle the *physical* work (distributed). This is why SaveAMeal scales faster than an NGO.

---

## 4. Personas

### Khun Siriporn (Donor) — Hotel F&B Manager, 42, Sukhumvit
- Needs to donate in under 5 minutes at closing time.
- Wants impact numbers for ESG/CSR quarterly reports.
- Will abandon the app if it adds friction to her closing routine.

### Nattapong "Pong" (Driver) — HR Assistant, 27, Rama IV
- Wants a Grab-like experience — see jobs on a map, pick one, do it, feel good.
- Needs clear step-by-step safety guidance; worried about handling rules.
- Will churn if a pickup ever goes wrong.

### Sister Maria (Beneficiary) — Shelter Coordinator, 54, Klong Toey
- Feeds ~60 children nightly; uncertainty about tonight's food is her main pain.
- Needs: simple toggle ("Accepting / Full"), see what's coming and when.
- Low tech comfort — shared tablet, big buttons, simple language.

---

## 5. Specified Feature Set (13 user-facing features)

### A — Donor Flow (4 features)
| ID | Feature |
|---|---|
| A1 | Login (email + password) — pre-approved accounts for demo |
| A2 | Donor Dashboard — total kg donated + recent donations |
| A3 | "Log Surplus Batch" form — category, quantity (kg/portions), expiry time, 1 photo |
| A4 | QR Code display screen — auto-generated from batch ID |

### B — Volunteer/Driver Flow (5 features)
| ID | Feature |
|---|---|
| B1 | Login → Map screen with pins of available pickups |
| B2 | Tap pin → batch details modal → "Accept Job" button |
| B3 | Navigation handled — "Open in Google Maps" external deep-link |
| B4 | "Scan QR at Donor" → 3-item safety checklist (yes/no) + 1 confirmation photo |
| B5 | "Arrived at Beneficiary" → verify → "Delivery Complete" screen |

### C — Beneficiary Flow (4 features)
| ID | Feature |
|---|---|
| C1 | Login → Status screen with "Accepting Food / Full" toggle |
| C2 | Incoming delivery banner when driver accepts a job |
| C3 | Map view with driver's live pin (real-time Firestore snapshots) |
| C4 | "Confirm Receipt" screen → 1–5 star rating + optional comment |

---

## 6. Architecture

### Conceptual
Three-sided marketplace. Information flows through the platform; physical food flows directly Donor → Volunteer → Beneficiary.

### Implementation Stack

| Concern | Specified in Docs | Implemented In Code |
|---|---|---|
| State management | Provider (ChangeNotifier) | Riverpod + riverpod_generator |
| Navigation | Not specified | GoRouter |
| UI structure | Role folders: `/donor`, `/driver`, `/beneficiary` | Clean Architecture `features/` |
| Backend | Firebase (Auth, Firestore, Storage, FCM, Cloud Functions) | Firebase (same) |
| External APIs | Google Maps (deep-link only), Device camera/GPS | Same |
| Offline | Explicitly out of scope | Hive added (diverges from spec) |

### Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | One doc per registered user (uid, name, email, role, status) |
| `batches` | Core entity — one doc per donated batch (`open → claimed → picked_up → delivered → closed`) |
| `driverLocations` | High-frequency live driver position writes (~30s while job active) |
| `impactMetrics` | Pre-aggregated counters per donor + global totals |
| `beneficiaries` | Beneficiary intake availability status |

### Batch Status Lifecycle
```
open → claimed → picked_up → delivered → closed
```
(+ `cancelled` added in code, not in spec — reasonable addition)

### The Four Cloud Functions (specified, not yet implemented)
| Function | Trigger | Action |
|---|---|---|
| `onBatchCreated` | new batch doc | FCM to nearby drivers |
| `onBatchClaimed` | status → "claimed" | FCM to donor (driver assigned) + beneficiary (incoming delivery + ETA) |
| `onDeliveryComplete` | status → "delivered" | Atomically update `impactMetrics` (kg, meals, CO₂e) |
| `cleanupLocations` | Scheduled daily | Remove `driverLocations` docs older than 24h |

### Impact Formulas
- `meals = portions` (if unit is portions) or `kg × 2.5` (if unit is kg)
- `CO₂e prevented (kg) = kg rescued × 2.5`

### End-to-End Transaction Flow
1. Donor logs batch → Firestore `batches` doc (status: open) + photo to Storage
2. QR generated from batch ID
3. `onBatchCreated` Cloud Function → FCM to nearby drivers
4. Driver sees live pin on map → taps Accept → atomic Firestore transaction
5. `onBatchClaimed` → FCM to donor + beneficiary (two "magic moments")
6. Driver location broadcasts to `driverLocations` every 30s
7. Driver scans QR at donor → 3-item checklist → photo → status: `picked_up`
8. Driver scans beneficiary QR → delivery photo → status: `delivered`
9. Beneficiary rates 1–5 stars → status: `closed`
10. `onDeliveryComplete` → atomically increments `impactMetrics`
11. Donor dashboard reflects impact in real-time

---

## 7. Security Considerations (from Architecture doc)
- Firebase Auth handles credential storage — app never sees passwords
- Firestore Security Rules enforce role-based access:
  - Donors: read/write only their own batches
  - Drivers: read all `status == "open"` batches; can only update to "claimed" if no `driverId` yet
  - Beneficiaries: read only their assigned batches; write only rating fields
- Race condition on "Accept Job" handled by Firestore transaction (read → verify status → write)
- Driver location readable only by matched beneficiary
- Location history auto-deleted after 24h (Cloud Function)

---

## 8. Explicitly Out of Scope
- Smart route pooling (multi-stop optimization)
- Offline mode & data sync conflict resolution
- Admin/NGO web backoffice
- Multilingual UI (English only)
- Tax-deduction PDF generation
- Beneficiary distribution logging (# people served)
- Driver verification / background checks

---

## 9. Project Timeline (WBS Summary)
| Phase | Window | Key Deliverables |
|---|---|---|
| 1.0 Planning & Design | May 19–21 | Concept doc, personas, journeys, Figma, WBS, Gantt |
| 2.0 Project Setup | May 22–23 | GitHub, Flutter project, Firebase, Maps API, shared models |
| 3.0 Shared Infrastructure | May 22–26 | Auth, widget library, QR utilities, push notifications |
| 4.0 Donor Role | May 24–28 | Dashboard, Log Batch, QR Display |
| 5.0 Driver Role | May 24–30 | Map, Job Detail, Pickup, Delivery |
| 6.0 Beneficiary Role | May 26–30 | Status, Confirm Receipt |
| 7.0 Integration & Testing | May 31–Jun 3 | E2E flows, manual QA, bug fixes |
| 8.0 Final Delivery | Jun 4–5 | Demo prep, final report, code submission |

---

## 10. Codebase vs. Documents Gap Analysis

### ✅ Implemented & Matching Spec

| Feature | Spec ID | Code Location |
|---|---|---|
| Login screen (email/password) | A1 / B1 / C1 | `features/auth/presentation/screens/login_screen.dart` |
| Register with role selection | WBS 3.1.3 | `features/auth/presentation/screens/register_screen.dart` |
| Role router on login | WBS 3.1.4 | `features/auth/presentation/screens/role_router_screen.dart` |
| Donor Dashboard (kg, meals, CO₂ + recent batches) | A2 | `features/donor/presentation/screens/donor_dashboard_screen.dart` |
| Log Surplus Batch form (category, qty, expiry, photo) | A3 | `features/donor/presentation/screens/log_surplus_form_screen.dart` |
| QR Code display screen | A4 | `features/donor/presentation/screens/batch_qr_screen.dart` |
| Driver Map with open batch pins | B1 | `features/driver/presentation/screens/driver_map_screen.dart` |
| Job Detail screen + Accept Job button | B2 | `features/driver/presentation/screens/job_detail_screen.dart` |
| Open in Google Maps navigation | B3 | `features/driver/presentation/screens/job_detail_screen.dart` |
| QR Scan at donor + safety checklist | B4 | `features/driver/presentation/screens/pickup_verification_screen.dart` + `safety_verification_screen.dart` |
| Delivery verification screen | B5 | `features/driver/presentation/screens/verify_delivery_screen.dart` |
| Delivery Complete screen | B5 | `features/driver/presentation/screens/delivery_completed_screen.dart` |
| Beneficiary status toggle (Accepting/Full) | C1 | `features/beneficiary/presentation/widgets/intake_status_toggle.dart` |
| Incoming delivery banner | C2 | `features/beneficiary/presentation/widgets/active_delivery_card.dart` |
| Live driver tracking map | C3 | `features/beneficiary/presentation/screens/tracking_screen.dart` |
| Confirm Receipt + 1–5 star rating | C4 | `features/beneficiary/presentation/screens/rate_delivery_screen.dart` |
| Firebase Auth integration | WBS 3.1.1–3.1.2 | `services/auth_service.dart` |
| Firestore CRUD + real-time listeners | Arch §5 | `services/firestore_service.dart` |
| Firebase Storage photo uploads | Arch §5 | `services/storage_service.dart` |
| QR generation (qr_flutter) | WBS 3.3.1 | `services/qr_service.dart` |
| Clean Architecture layer separation | CLAUDE.md | All `features/` folders |
| Atomic "Accept Job" Firestore transaction | Arch §9 | `features/driver/data/datasources/driver_remote_datasource.dart` |
| `impactMetrics` collection structure | Arch §7 | `core/constants/firestore_constants.dart` |
| Driver location model + collection | Arch §7 | `core/models/driver_location_model.dart` |

---

### ❌ Not Yet Implemented (in spec, missing in code)

| # | Feature | Spec Reference | Priority |
|---|---|---|---|
| 1 | **FCM push notifications** — FCM token registration on login | WBS 3.4.1 | HIGH |
| 2 | **Cloud Function: `onBatchCreated`** — notify nearby drivers when batch posted | Arch §5 / WBS 3.4.2 | HIGH |
| 3 | **Cloud Function: `onBatchClaimed`** — FCM to donor ("driver assigned") + beneficiary ("incoming delivery + ETA") | Arch §5 / WBS 3.4.3–3.4.4 | HIGH |
| 4 | **Cloud Function: `onDeliveryComplete`** — atomically increment `impactMetrics` (kg, meals, CO₂e) | Arch §5 | HIGH |
| 5 | **Cloud Function: `cleanupLocations`** — daily scheduled deletion of stale `driverLocations` | Arch §5 | MEDIUM |
| 6 | **Live driver location broadcasting** — periodic writes to `driverLocations` every ~30s while job active | Arch §7 / WBS 5.5.1 | HIGH |
| 7 | **Location broadcast cleanup** — stop writing + delete doc on job complete/cancel | WBS 5.5.2 | MEDIUM |
| 8 | **ETA calculation** — driver location → shelter distance/time for beneficiary screen | WBS 6.1.5 | MEDIUM |
| 9 | **QR scanner fallback** — manual batch-ID text entry if scan fails | WBS 3.3.3 | MEDIUM |
| 10 | **Notification deep-linking** — tap FCM notification → navigate to relevant screen | WBS 3.4.5 | MEDIUM |
| 11 | **`impactMetrics` global document** — platform-wide totals (used for future dashboard) | Arch §7 | LOW |

---

### ⚠️ In Code But Diverges From Spec

| # | What's in Code | What Spec Says | Assessment |
|---|---|---|---|
| 1 | **Riverpod** state management (flutter_riverpod + riverpod_generator) | **Provider** (ChangeNotifier) | Better choice; no rework needed. CLAUDE.md already specifies Riverpod. |
| 2 | **Clean Architecture** (domain/data/presentation + use cases + repositories) | Simple **Service Layer** (AuthService, FirestoreService, etc.) | Better architecture; services still exist as the innermost data layer. |
| 3 | **`volunteer/` feature folder** (VolunteerQueueScreen, VolunteerDeliveryScannerScreen) | No separate "volunteer" feature — drivers are the volunteer role | Confusing duplication. `volunteer` screens appear to overlap with `driver` screens. Needs reconciliation. |
| 4 | **BatchSummaryScreen** — extra review step before QR display | Spec shows: Form → QR directly | Extra step not in spec. Fine to keep if UX decision is intentional. |
| 5 | **ScannerScreen in Donor flow** — barcode scanning for product name lookup | Not in spec | Good enhancement beyond spec, but not required. |
| 6 | **Hive local caching** (`donor_batches`, `donor_metrics`) in `main.dart` | Explicitly **out of scope**: "Offline mode deliberately excluded" | Should be removed or left as stub-only if it causes complexity. |
| 7 | **`/donor/log`** routes to `ScannerScreen` as first step | Spec: form is the entry point | Navigation entry point differs from spec. |
| 8 | **GoRouter** for navigation | Not specified | Fine — modern Flutter navigation. No change needed. |
| 9 | **Firebase Crashlytics** | Not mentioned in spec | Reasonable addition. Keep. |

---

### 🔧 Implementation Priority Queue

Based on the gap analysis, ordered by impact on the demo:

**Must-Have Before Demo (High Priority)**
1. FCM token registration on login (`services/` layer + `auth_service.dart`)
2. Live driver location broadcasting while job is active (`location_service.dart` is stubbed)
3. Cloud Functions: `onBatchClaimed` (the two "magic moments" Khun Siriporn and Sister Maria expect)
4. Cloud Function: `onDeliveryComplete` (impact metrics won't update without this)

**Should-Have (Medium Priority)**
5. QR scan fallback — manual batch-ID entry in scanner screens
6. ETA calculation on beneficiary tracking screen
7. Cloud Function: `onBatchCreated` (driver discovery notifications — marked stretch in WBS)
8. Notification deep-linking

**Nice-to-Have / Cleanup**
9. Reconcile `volunteer/` feature vs `driver/` feature — remove or merge
10. Cloud Function: `cleanupLocations`
11. Decide whether to keep or remove Hive offline caching (it's out of scope per spec)
12. `impactMetrics/global` document population

---

## 11. Team Ownership Map

| Member | Role | Spec Ownership | Implemented Code |
|---|---|---|---|
| M1 — Nang Hayman Aye Mya | Tech Lead / Backend | Firebase, auth, role router, shared models, deployment | `services/`, `features/auth/`, `core/` |
| M2 — Khin Nadi Ko | Donor Workflow | Donor Dashboard, Log Batch, QR Display | `features/donor/` |
| M3 — Chotiya Khawsanga | Driver Map | Driver Map, Google Maps, Job Detail, accept-job logic | `features/driver/screens/driver_map_screen`, `job_detail_screen` |
| M4 — Nichapa Jongsakulsiri | Driver Workflow + Beneficiary Confirm | Pickup Checklist, QR scanner, Delivery Confirm, Beneficiary receipt+rating | `features/driver/screens/pickup_*`, `verify_delivery`, `features/beneficiary/screens/rate_delivery` |
| M5 — Warisara Luechairam | State / Widgets / Beneficiary Status | Shared widget library, state management, Beneficiary Status screen | `shared/`, `features/beneficiary/screens/beneficiary_dashboard`, `tracking_screen` |
