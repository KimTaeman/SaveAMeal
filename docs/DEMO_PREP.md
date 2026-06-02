# SaveAMeal Demo Prep
**Demo date:** June 4–5, 2026
**Duration:** ~3 minutes
**Devices needed:** 3 (donor phone, driver phone, beneficiary tablet)

---

## Step 1 — Create Firebase Auth accounts

Do this in [Firebase Console → Authentication → Users → Add User](https://console.firebase.google.com/project/saveameal-87187/authentication/users).

Create these 3 accounts and **record their UIDs**:

| Role | Email | Password | Notes |
|---|---|---|---|
| Donor | `demo.donor@saveameal.th` | `Demo1234!` | Khun Siriporn |
| Driver | `demo.driver@saveameal.th` | `Demo1234!` | Nattapong |
| Beneficiary | `demo.beneficiary@saveameal.th` | `Demo1234!` | Sister Maria |

---

## Step 2 — Seed Firestore with demo accounts

From `tools/seed/`, with your `serviceAccountKey.json`:

```bash
cd tools/seed

# Register donor
node seed.js --key serviceAccountKey.json --add-donor <DONOR_UID>

# Register driver
node seed.js --key serviceAccountKey.json --add-driver <DRIVER_UID>

# Register beneficiary (creates both users doc AND beneficiaries doc)
node seed.js --key serviceAccountKey.json --add-beneficiary <BENEFICIARY_UID>
```

---

## Step 3 — Seed demo batch data

Run the full seed with **clean** to reset batches. Then manually create one `open` batch in Firestore Console that uses your real demo UIDs:

```bash
# Full seed (resets all collection data)
node seed.js --key serviceAccountKey.json --clean
```

Then in Firebase Console → Firestore → `batches` collection, **edit `batch_002`** (Central Embassy → Klongtoey) and update:

```
donorId:        <DONOR_UID>
beneficiaryId:  <BENEFICIARY_UID>
status:         open
```

This is the batch used in the live demo.

> **Why:** The app uses Firebase Auth UIDs as document IDs. Batch `beneficiaryId` and `donorId` must match the real Auth UIDs for push notifications and delivery tracking to work.

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

**Narrate:** *"Khun Siriporn manages F&B at a hotel. Tonight the buffet has leftover food that won't be served tomorrow."*

**On donor device:**
1. Tap **+ Log Surplus** from the Dashboard
2. Fill form: Category = `Cooked Meals`, Quantity = `38 portions`, Expiry = `tomorrow 6am`
3. Add a photo (tap camera icon)
4. Tap **Submit**
5. QR code appears — *"This QR code travels with the food"*

**Driver device:** A push notification arrives: *"New pickup available — Central Embassy · 5.7 kg"*

---

### Scene 2 — Driver accepts and heads to pickup (~45 sec)

**Narrate:** *"Nattapong is heading home after work. He opens SaveAMeal and sees a pickup nearby."*

**On driver device:**
1. Tap the pin on the map → Job Detail screen appears
2. Show: pickup address, drop-off shelter, batch summary (38 portions)
3. Tap **Accept Job**

**Donor device:** Push notification arrives — *"Driver is on the way · Your batch is being picked up"*

**Beneficiary tablet:** Push notification arrives — *"Delivery incoming · 5.7 kg from Central Embassy"*
- Show: Beneficiary Dashboard → active delivery banner — *"A volunteer is on the way"*
- Tap **Track Delivery** → map with driver pin

---

### Scene 3 — Pickup and delivery (~60 sec)

**Narrate:** *"Nattapong arrives at the hotel."*

**On driver device:**
1. **ClaimRescueScreen** — "Status: En Route to Pick-up", tap **Arrived at Pick-up**
2. **PickupVerificationScreen** — scan the donor's QR code (or tap "Enter code manually" → type `batch_002`)
3. **SafetyVerificationScreen** — check all 3 safety items, take a photo of the food
4. Tap **Confirm & Complete Pickup** → *"En Route to Beneficiary"*

**Beneficiary tablet:** Driver pin on map moves toward the shelter

**On driver device:**
5. Arrive at shelter → tap **Arrived at Drop-off**
6. **VerifyDeliveryScreen** — shows "Batch #002 / 38 Portions", check both items
7. Tap **Confirm Delivery Completion**

**Delivery Complete screen:** Impact card shows CO₂ saved + meals provided + points earned

---

### Scene 4 — Beneficiary confirms (~30 sec)

**On beneficiary tablet:**
1. Push notification: *"Food has arrived — Tap to confirm receipt"*
2. Tap notification → Rate Delivery screen
3. Give 5 stars, add note: *"Kids will eat well tomorrow"*
4. Tap **Submit**

**Donor device:** Dashboard impact numbers update in real time — *"Donor sees their contribution reflected instantly"*

---

## Release Checklist

- [ ] All 3 demo accounts created in Firebase Console
- [ ] `users/{DONOR_UID}`, `users/{DRIVER_UID}`, `users/{BENEFICIARY_UID}` docs exist in Firestore
- [ ] `beneficiaries/{BENEFICIARY_UID}` doc exists with `lat`/`lng`
- [ ] Demo batch `batch_002` updated with real `donorId` and `beneficiaryId`
- [ ] FCM tokens populated for all 3 accounts (log in + log out to trigger)
- [ ] Cloud Functions deployed (`firebase deploy --only functions`)
- [ ] Full dry-run completed with all 3 devices before demo day
- [ ] Git tag created: `git tag v1.0-submission && git push origin v1.0-submission`
- [ ] Professor's GitHub access verified

---

## Emergency fallbacks

| Problem | Fallback |
|---|---|
| QR scanner won't read | Tap "Enter code manually" → type the batch ID shown below the QR |
| Push notification doesn't arrive | Refresh the relevant screen — Firestore real-time streams update the UI anyway |
| Location permission denied | Driver flow still works; beneficiary tracking map won't show driver pin |
| Cloud Functions not deployed | Impact metrics won't update; all other flows still work |
