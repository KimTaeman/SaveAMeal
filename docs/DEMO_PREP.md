# SaveAMeal Demo Prep

**Demo date:** June 4–5, 2026
**Duration:** ~3 minutes
**Devices needed:** 3 (donor phone, driver phone, beneficiary tablet)

---

## Step 1 — Run the one-command demo setup

From `tools/seed/`, with your `serviceAccountKey.json` placed there:

```bash
cd tools/seed
npm run demo
```

This single command:
- Creates the 3 Firebase Auth accounts (or skips if they already exist)
- Registers them in Firestore `users/` with correct roles
- Creates the `beneficiaries/` doc for Sister Maria's shelter
- Creates `demo_batch_001` — an `open` batch tied to the donor + beneficiary UIDs
- Zeroes the donor's `impactMetrics` doc

**Demo credentials** (all password `qwer1234`):

| Role        | Email                           | Notes         |
| ----------- | ------------------------------- | ------------- |
| Donor       | `demo.donor@saveameal.th`       | Khun Siriporn |
| Driver      | `demo.driver@saveameal.th`      | Nattapong     |
| Beneficiary | `demo.beneficiary@saveameal.th` | Sister Maria  |

The script prints each account's Firebase Auth UID at the end — keep these handy for the FCM verification step.

> **Re-running:** Safe to run multiple times. Auth accounts are fetched by email before creation, so no duplicates are made.

---

## Step 2 — Deploy Firestore + Storage security rules

**Required — editing profiles and uploading photos will fail with `permission-denied` until these are deployed.**

```bash
firebase deploy --only firestore:rules,storage
```

This deploys `firestore.rules` and `storage.rules` from the repo root.
The storage rules were missing the `users/` path — added in this version.

> Requires Firebase CLI: `npm install -g firebase-tools` then `firebase login`.

---

## Step 4 — Verify FCM notifications work

Before demo day, test push notifications:

1. Log in as donor on donor device → check `users/{DONOR_UID}.fcmToken` is populated in Firestore Console
2. Log in as driver on driver device → check Firebase Console → Messaging → Topics → `new_batch_available` shows subscriber
3. Log in as beneficiary on beneficiary device → check `users/{BENEFICIARY_UID}.fcmToken` populated

If tokens are missing, log out and log back in.

---

## Step 5 — Deploy Cloud Functions

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions --key tools/seed/serviceAccountKey.json
```

> Requires Blaze (pay-as-you-go) plan. iOS devices also need APNs Auth Key in Firebase Console → Project Settings → Cloud Messaging.

---

## 3-Minute Demo Script

### Setup (before presenting)

- Donor device: logged in as `demo.donor@saveameal.th`, on Donor Dashboard
- Driver device: logged in as `demo.driver@saveameal.th`, on Driver Map
- Beneficiary tablet: logged in as `demo.beneficiary@saveameal.th`, on Beneficiary Dashboard (status: "Accepting Food")

---

### Scene 1 — Donor logs a batch (~45 sec)

**Narrate:** _"Khun Siriporn manages F&B at a hotel. Tonight the buffet has leftover food that won't be served tomorrow."_

**On donor device:**

1. Tap **+ Log Surplus** from the Dashboard → tap **Enter Manually** to skip the barcode scanner
2. Fill form: Category = `Other`, Quantity = `15` kg, Expiry = pick a time ~8h from now
3. Optionally add a photo (tap camera icon)
4. Tap **Add to Batch** → Batch Summary screen appears
5. Tap **Submit Batch** → **QR code appears** — _"This QR code travels with the food"_

**Driver device:** A push notification arrives: _"New pickup available — Central Embassy · 5.7 kg"_

---

### Scene 2 — Driver accepts and heads to pickup (~45 sec)

**Narrate:** _"Nattapong is heading home after work. He opens SaveAMeal and sees a pickup nearby."_

**On driver device:**

1. Tap the pin on the map → Job Detail screen appears
2. Show: pickup address, drop-off shelter, batch summary (38 portions)
3. Tap **Accept Job**

**Donor device:** Push notification arrives — _"Driver is on the way · Your batch is being picked up"_

**Beneficiary tablet:** Push notification arrives — _"Delivery incoming · 5.7 kg from Central Embassy"_

- Show: Beneficiary Dashboard → active delivery banner — _"A volunteer is on the way"_
- Tap **Track Delivery** → map with driver pin

---

### Scene 3 — Pickup and delivery (~60 sec)

**Narrate:** _"Nattapong arrives at the hotel."_

**On driver device:**

1. **ClaimRescueScreen** — "Status: En Route to Pick-up", tap **Arrived at Pick-up**
2. **PickupVerificationScreen** — scan the donor's QR code (or tap "Enter code manually" → type `demo_batch_001`)
3. **SafetyVerificationScreen** — check all 3 safety items, take a photo of the food
4. Tap **Confirm & Complete Pickup** → _"En Route to Beneficiary"_

**Beneficiary tablet:** Driver pin on map moves toward the shelter

**On driver device:** 5. Arrive at shelter → tap **Arrived at Drop-off** 6. **VerifyDeliveryScreen** — shows "Batch #002 / 38 Portions", check both items 7. Tap **Confirm Delivery Completion**

**Delivery Complete screen:** Impact card shows CO₂ saved + meals provided + points earned

---

### Scene 4 — Beneficiary confirms (~30 sec)

**On beneficiary tablet:**

1. Push notification: _"Food has arrived — Tap to confirm receipt"_
2. Tap notification → Rate Delivery screen
3. Give 5 stars, add note: _"Kids will eat well tomorrow"_
4. Tap **Submit**

**Donor device:** Dashboard impact numbers update in real time — _"Donor sees their contribution reflected instantly"_

---

## Release Checklist

- [ ] `firebase deploy --only firestore:rules,storage` run from repo root ← **required for profile edits to work**
- [ ] `npm run demo` completed successfully from `tools/seed/` (creates accounts + batch in one shot)
- [ ] `users/{DONOR_UID}`, `users/{DRIVER_UID}`, `users/{BENEFICIARY_UID}` docs exist in Firestore
- [ ] `beneficiaries/{BENEFICIARY_UID}` doc exists with `lat`/`lng`
- [ ] `batches/demo_batch_001` exists with correct `donorId` and `beneficiaryId`
- [ ] FCM tokens populated for all 3 accounts (log in + log out to trigger)
- [ ] Cloud Functions deployed (`firebase deploy --only functions`)
- [ ] Full dry-run completed with all 3 devices before demo day
- [ ] Git tag created: `git tag v1.0-submission && git push origin v1.0-submission`
- [ ] Professor's GitHub access verified

---

## Emergency fallbacks

| Problem                          | Fallback                                                                       |
| -------------------------------- | ------------------------------------------------------------------------------ |
| QR scanner won't read            | Tap "Enter code manually" → type the batch ID shown below the QR               |
| Push notification doesn't arrive | Refresh the relevant screen — Firestore real-time streams update the UI anyway |
| Location permission denied       | Driver flow still works; beneficiary tracking map won't show driver pin        |
| Cloud Functions not deployed     | Impact metrics won't update; all other flows still work                        |
