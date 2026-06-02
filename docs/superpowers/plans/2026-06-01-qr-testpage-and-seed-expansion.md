# QR Test Page & Seed Data Expansion — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a self-contained HTML page of scannable test codes for Donor (food EAN-13 barcodes) and Driver (batch QR codes), and expand the Firestore seed script to 10 users, 4 beneficiaries, 12 batches, and 6 impact metric records with realistic Thai food rescue data.

**Architecture:** Two independent files. The HTML page is a static asset with no build step — it uses CDN libraries (JsBarcode, QRCode.js) and hardcodes the same batch IDs used in the seed script. The seed script replaces only its four data arrays; all helper functions, CLI flags, and `main()` logic remain unchanged.

**Tech Stack:** HTML/CSS/JS (JsBarcode 3.11.6, QRCode.js 1.0.0 via CDN), Node.js seed script (firebase-admin)

---

## File Map

| Action | Path | Responsibility |
|--------|------|---------------|
| Create | `docs/test-qr/index.html` | Self-contained scan-code reference page |
| Modify | `tools/seed/seed.js` | Replace BENEFICIARIES, USERS, BATCHES, IMPACT_METRICS arrays and summary log |

---

### Task 1: Create the HTML test page

**Files:**
- Create: `docs/test-qr/index.html`

- [ ] **Step 1: Create `docs/test-qr/index.html` with the following exact content**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SaveAMeal — Test Scan Codes</title>
  <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #f5f5f5; padding: 24px; color: #1a1a1a; }
    h1 { text-align: center; margin-bottom: 8px; font-size: 1.4rem; }
    .intro { text-align: center; color: #666; font-size: .85rem; margin-bottom: 32px; }
    h2 { font-size: 1rem; color: #333; margin: 32px 0 6px; padding-bottom: 8px; border-bottom: 2px solid #ddd; }
    .hint { font-size: .78rem; color: #666; margin-bottom: 14px; }
    .role-badge { display: inline-block; font-size: .68rem; font-weight: 700; letter-spacing: 1px;
                  padding: 2px 8px; border-radius: 12px; margin-bottom: 8px; }
    .donor-badge  { background: #e3f2fd; color: #1565c0; }
    .driver-badge { background: #e8f5e9; color: #2e7d32; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 14px; }
    .card { background: #fff; border-radius: 12px; padding: 18px 16px; text-align: center;
            box-shadow: 0 1px 4px rgba(0,0,0,.08); }
    .card h3 { font-size: .88rem; margin-bottom: 2px; }
    .card .sub { font-size: .73rem; color: #888; margin-bottom: 10px; }
    .card .code { font-size: .68rem; color: #aaa; margin-top: 8px; font-family: monospace; letter-spacing: 1px; }
    .barcode-wrap svg { max-width: 100%; }
    .status-open    { color: #2e7d32; font-weight: 600; }
    .status-claimed { color: #e65100; font-weight: 600; }
    @media print {
      body { background: #fff; padding: 8px; }
      .card { box-shadow: none; border: 1px solid #ddd; page-break-inside: avoid; }
    }
  </style>
</head>
<body>

<h1>SaveAMeal — Test Scan Codes</h1>
<p class="intro">Open this page in a desktop browser. Use your phone (running the app) to scan the codes.</p>

<!-- ── Section A: Donor food barcodes ─────────────────────────────────── -->
<h2>Section A — Food Barcodes &nbsp;<span class="role-badge donor-badge">DONOR · Log Surplus</span></h2>
<p class="hint">In the app → Donor → Log Surplus → tap the camera icon → scan any barcode below.</p>
<div class="grid" id="barcodes"></div>

<!-- ── Section B: Driver batch QR codes ──────────────────────────────── -->
<h2>Section B — Batch QR Codes &nbsp;<span class="role-badge driver-badge">DRIVER · Verify Pickup</span></h2>
<p class="hint">Driver claims a batch in-app → navigates to Verify Pickup → scans the matching QR below.</p>
<div class="grid" id="qrcodes"></div>

<script>
// ── Section A: Food product EAN-13 barcodes ──────────────────────────────────
const FOODS = [
  { name: 'Mama Tom Yum Noodles', brand: 'Mama',        ean: '8850987130021' },
  { name: 'Lays Classic Chips',   brand: "Lay's TH",    ean: '8850018110060' },
  { name: 'Oishi Green Tea',      brand: 'Oishi',       ean: '8850007107019' },
  { name: 'Pocky Chocolate',      brand: 'Glico',       ean: '4901005508033' },
  { name: 'Milo UHT',             brand: 'Nestlé',      ean: '9556000021107' },
  { name: 'Bear Brand Milk',      brand: 'Nestlé',      ean: '7613034426826' },
];

const bGrid = document.getElementById('barcodes');
FOODS.forEach(f => {
  const card = document.createElement('div');
  card.className = 'card';
  card.innerHTML = `
    <div class="role-badge donor-badge">DONOR</div>
    <h3>${f.name}</h3>
    <div class="sub">${f.brand}</div>
    <div class="barcode-wrap"><svg id="bc-${f.ean}"></svg></div>
    <div class="code">${f.ean}</div>
  `;
  bGrid.appendChild(card);
  JsBarcode(`#bc-${f.ean}`, f.ean, {
    format: 'EAN13', displayValue: false, margin: 4, height: 60, lineColor: '#222',
  });
});

// ── Section B: Batch QR codes ─────────────────────────────────────────────────
const BATCHES = [
  { id: 'batch_001', donor: 'Sri Silom Restaurant',        status: 'open'    },
  { id: 'batch_002', donor: 'Central Embassy Food Court',  status: 'open'    },
  { id: 'batch_003', donor: 'Sri Silom Restaurant',        status: 'open'    },
  { id: 'batch_004', donor: 'Central Embassy Food Court',  status: 'claimed' },
  { id: 'batch_006', donor: 'Mövenpick Hotel Bangkok',     status: 'open'    },
  { id: 'batch_007', donor: 'Anchana Bakery & Café',       status: 'open'    },
  { id: 'batch_008', donor: 'Mövenpick Hotel Bangkok',     status: 'claimed' },
];

const qGrid = document.getElementById('qrcodes');
BATCHES.forEach(b => {
  const card = document.createElement('div');
  card.className = 'card';
  const cls = b.status === 'claimed' ? 'status-claimed' : 'status-open';
  card.innerHTML = `
    <div class="role-badge driver-badge">DRIVER</div>
    <h3>${b.donor}</h3>
    <div class="sub">Status: <span class="${cls}">${b.status}</span></div>
    <div id="qr-${b.id}"></div>
    <div class="code">${b.id}</div>
  `;
  qGrid.appendChild(card);
  new QRCode(document.getElementById(`qr-${b.id}`), {
    text: b.id, width: 180, height: 180,
    colorDark: '#222', colorLight: '#ffffff',
    correctLevel: QRCode.CorrectLevel.M,
  });
});
</script>
</body>
</html>
```

- [ ] **Step 2: Open in a browser and verify**

Open `docs/test-qr/index.html` in Chrome or Edge. You should see:
- Section A: 6 scannable EAN-13 barcodes (black bars on white background)
- Section B: 7 QR codes, each labelled with batch ID and status

If Section A barcodes fail to render, check the browser console — JsBarcode will log a message if an EAN-13 check digit is wrong.

- [ ] **Step 3: Commit**

```bash
git add docs/test-qr/index.html
git commit -m "feat: add test scan codes HTML page for Donor and Driver flows"
```

---

### Task 2: Expand seed data arrays in tools/seed/seed.js

**Files:**
- Modify: `tools/seed/seed.js` (replace BENEFICIARIES, USERS, BATCHES, IMPACT_METRICS constants and update summary log)

**Context:** `category` in batch items is stored as a plain Material icon name string — no enum validation. Valid values used in this codebase: `local_dining`, `bakery_dining`, `local_pizza`, `local_cafe`, `local_grocery`. The `status` string enum is: `open | claimed | pickedUp | delivered | closed | cancelled`. The `role` string enum is: `donor | driver | beneficiary`.

- [ ] **Step 1: Replace the BENEFICIARIES constant**

Find and replace the entire `const BENEFICIARIES = [...]` block with:

```js
const BENEFICIARIES = [
  {
    id:      'ben_001',
    name:    'Baan Saeng Tawan Shelter',
    address: '12 Lat Phrao Soi 15, Chankasem, Chatuchak, Bangkok 10230',
  },
  {
    id:      'ben_002',
    name:    'Klongtoey Community Center',
    address: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
  },
  {
    id:      'ben_003',
    name:    'Prateep Foundation Elderly Care',
    address: '152/88 Sukhumvit Soi 26, Khlong Toei, Bangkok 10110',
  },
  {
    id:      'ben_004',
    name:    'Bangkapi Community Kitchen',
    address: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
  },
];
```

- [ ] **Step 2: Replace the USERS constant**

Find and replace the entire `const USERS = [...]` block with:

```js
const USERS = [
  // ── Donors ────────────────────────────────────────────────────────────────
  {
    uid: 'donor_001', name: 'Somchai Kamolrat',
    email: 'somchai@srisilom.co.th', role: 'donor',
    phone: '+66812345601', orgName: 'Sri Silom Restaurant', status: null, points: 0,
  },
  {
    uid: 'donor_002', name: 'Naree Wongkasem',
    email: 'naree@centralembassy.th', role: 'donor',
    phone: '+66812345602', orgName: 'Central Embassy Food Court', status: null, points: 0,
  },
  {
    uid: 'donor_003', name: 'Prasert Jaidee',
    email: 'prasert@movenpick-bkk.com', role: 'donor',
    phone: '+66812345603', orgName: 'Mövenpick Hotel Bangkok', status: null, points: 0,
  },
  {
    uid: 'donor_004', name: 'Anchana Burin',
    email: 'anchana@anchanabakery.th', role: 'donor',
    phone: '+66812345604', orgName: 'Anchana Bakery & Café', status: null, points: 0,
  },
  {
    uid: 'donor_005', name: 'Theerawat Sombat',
    email: 'theerawat@bangkapi-school.go.th', role: 'donor',
    phone: '+66812345605', orgName: 'Bangkapi School Canteen', status: null, points: 0,
  },
  {
    uid: 'donor_006', name: 'Suphot Rattana',
    email: 'suphot@711sukhumvit.th', role: 'donor',
    phone: '+66812345606', orgName: '7-Eleven Sukhumvit 11', status: null, points: 0,
  },

  // ── Drivers ───────────────────────────────────────────────────────────────
  {
    uid: 'driver_001', name: 'Krit Chaiwong',
    email: 'krit.chaiwong@saveameal.th', role: 'driver',
    phone: '+66812345611', orgName: null, status: null, points: 340,
  },
  {
    uid: 'driver_002', name: 'Amporn Suwan',
    email: 'amporn.suwan@saveameal.th', role: 'driver',
    phone: '+66812345612', orgName: null, status: null, points: 280,
  },
  {
    uid: 'driver_003', name: 'Montri Phansiri',
    email: 'montri.phansiri@saveameal.th', role: 'driver',
    phone: '+66812345613', orgName: null, status: null, points: 150,
  },

  // ── Beneficiary ───────────────────────────────────────────────────────────
  {
    uid: 'bene_user_001', name: 'Wanchai Thongsuk',
    email: 'wanchai@baansaengtawan.org', role: 'beneficiary',
    phone: '+66812345620', orgName: 'Baan Saeng Tawan Shelter',
    status: 'accepting', points: 0,
  },
];
```

- [ ] **Step 3: Replace the BATCHES constant**

Find and replace the entire `const BATCHES = [...]` block with:

```js
const BATCHES = [
  // ── open: Sri Silom → Baan Saeng Tawan ──────────────────────────────────
  {
    id: 'batch_001', donorId: 'donor_001', donorName: 'Sri Silom Restaurant',
    donorContact: '+66812345601',
    pickupAddress: '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    beneficiaryId: 'ben_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'open', pickupWindowStart: '14:00', pickupWindowEnd: '16:00',
    specialInstructions: 'Please bring insulated bags. Ask for Khun Somchai at reception.',
    items: [
      { name: 'Pad Thai',          category: 'local_dining',  weightKg: 3.0, expiryTime: hoursFrom(6),  photoUrl: null },
      { name: 'Tom Kha Soup',      category: 'local_dining',  weightKg: 2.5, expiryTime: hoursFrom(6),  photoUrl: null },
      { name: 'Jasmine Rice',      category: 'local_dining',  weightKg: 4.0, expiryTime: hoursFrom(8),  photoUrl: null },
      { name: 'Mango Sticky Rice', category: 'bakery_dining', weightKg: 1.5, expiryTime: hoursFrom(4),  photoUrl: null },
    ],
    driverId: null, qrCode: 'batch_001', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },

  // ── open: Central Embassy → Klongtoey ────────────────────────────────────
  {
    id: 'batch_002', donorId: 'donor_002', donorName: 'Central Embassy Food Court',
    donorContact: '+66812345602',
    pickupAddress: '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId: 'ben_002', beneficiaryName: 'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'open', pickupWindowStart: '21:00', pickupWindowEnd: '22:30',
    specialInstructions: 'Closing time pickup. Use staff entrance on the left side.',
    items: [
      { name: 'Margherita Pizza ×6 slices', category: 'local_pizza',   weightKg: 1.8, expiryTime: hoursFrom(2),  photoUrl: null },
      { name: 'Caesar Salad',               category: 'local_dining',  weightKg: 0.9, expiryTime: hoursFrom(2),  photoUrl: null },
      { name: 'Croissant ×8',               category: 'bakery_dining', weightKg: 0.6, expiryTime: hoursFrom(18), photoUrl: null },
    ],
    driverId: null, qrCode: 'batch_002', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },

  // ── open: Sri Silom → Klongtoey ──────────────────────────────────────────
  {
    id: 'batch_003', donorId: 'donor_001', donorName: 'Sri Silom Restaurant',
    donorContact: '+66812345601',
    pickupAddress: '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    beneficiaryId: 'ben_002', beneficiaryName: 'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'open', pickupWindowStart: '19:00', pickupWindowEnd: '20:30',
    specialInstructions: null,
    items: [
      { name: 'Green Curry (large)',  category: 'local_dining', weightKg: 3.5, expiryTime: hoursFrom(6), photoUrl: null },
      { name: 'Som Tum Salad',        category: 'local_dining', weightKg: 1.2, expiryTime: hoursFrom(4), photoUrl: null },
    ],
    driverId: null, qrCode: 'batch_003', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },

  // ── claimed: driver_001 en route to Central Embassy ──────────────────────
  {
    id: 'batch_004', donorId: 'donor_002', donorName: 'Central Embassy Food Court',
    donorContact: '+66812345602',
    pickupAddress: '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId: 'ben_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'claimed', pickupWindowStart: '18:00', pickupWindowEnd: '19:00',
    specialInstructions: 'Handle with care — soup containers. Driver should call first.',
    items: [
      { name: 'Tom Yum Soup ×10 portions', category: 'local_dining', weightKg: 5.0, expiryTime: hoursFrom(3), photoUrl: null },
      { name: 'Khao Man Gai ×8 portions',  category: 'local_dining', weightKg: 4.0, expiryTime: hoursFrom(3), photoUrl: null },
    ],
    driverId: 'driver_001', qrCode: 'batch_004', claimedAt: hoursAgo(0.5), pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: daysAgo(1), updatedAt: hoursAgo(0.5),
  },

  // ── delivered: history record (Sri Silom) ────────────────────────────────
  {
    id: 'batch_005', donorId: 'donor_001', donorName: 'Sri Silom Restaurant',
    donorContact: '+66812345601',
    pickupAddress: '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    beneficiaryId: 'ben_002', beneficiaryName: 'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'delivered', pickupWindowStart: '14:00', pickupWindowEnd: '15:30',
    specialInstructions: null,
    items: [
      { name: 'Fried Rice family size', category: 'local_dining', weightKg: 4.0, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Spring Rolls ×12',       category: 'local_dining', weightKg: 1.0, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Fruit Platter',          category: 'local_dining', weightKg: 2.0, expiryTime: daysAgo(0.5), photoUrl: null },
    ],
    driverId: 'driver_002', qrCode: 'batch_005',
    claimedAt: daysAgo(1), pickedUpAt: daysAgo(1), deliveredAt: daysAgo(1),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'All items delivered in good condition. Shelter staff confirmed.',
    rating: 5, feedback: 'Great rescue! Food was still warm.',
    createdAt: daysAgo(1), updatedAt: daysAgo(1),
  },

  // ── open: Mövenpick Hotel → Prateep Foundation ───────────────────────────
  {
    id: 'batch_006', donorId: 'donor_003', donorName: 'Mövenpick Hotel Bangkok',
    donorContact: '+66812345603',
    pickupAddress: '672 Wireless Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId: 'ben_003', beneficiaryName: 'Prateep Foundation Elderly Care',
    beneficiaryAddress: '152/88 Sukhumvit Soi 26, Bangkok 10110',
    status: 'open', pickupWindowStart: '22:00', pickupWindowEnd: '23:00',
    specialInstructions: 'After-dinner buffet leftovers. Use loading bay entrance on Soi 30.',
    items: [
      { name: 'International Buffet Assorted', category: 'local_dining',  weightKg: 8.0, expiryTime: hoursFrom(3),  photoUrl: null },
      { name: 'Bread Rolls ×20',              category: 'bakery_dining', weightKg: 2.0, expiryTime: hoursFrom(24), photoUrl: null },
      { name: 'Fresh Salad Assorted',         category: 'local_dining',  weightKg: 1.5, expiryTime: hoursFrom(3),  photoUrl: null },
      { name: 'Fruit Station Platter',        category: 'local_dining',  weightKg: 3.0, expiryTime: hoursFrom(6),  photoUrl: null },
      { name: 'Cheese & Cold Cuts',           category: 'local_dining',  weightKg: 1.0, expiryTime: hoursFrom(4),  photoUrl: null },
    ],
    driverId: null, qrCode: 'batch_006', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },

  // ── open: Anchana Bakery → Bangkapi Kitchen ──────────────────────────────
  {
    id: 'batch_007', donorId: 'donor_004', donorName: 'Anchana Bakery & Café',
    donorContact: '+66812345604',
    pickupAddress: '55/3 Ramkhamhaeng Rd, Hua Mak, Bang Kapi, Bangkok 10240',
    beneficiaryId: 'ben_004', beneficiaryName: 'Bangkapi Community Kitchen',
    beneficiaryAddress: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
    status: 'open', pickupWindowStart: '18:30', pickupWindowEnd: '19:30',
    specialInstructions: 'End-of-day bakery surplus. Ring doorbell — ask for Khun Anchana.',
    items: [
      { name: 'Sourdough Loaves ×4',      category: 'bakery_dining', weightKg: 2.4, expiryTime: hoursFrom(20), photoUrl: null },
      { name: 'Almond Croissants ×10',    category: 'bakery_dining', weightKg: 1.2, expiryTime: hoursFrom(18), photoUrl: null },
      { name: 'Danish Pastries ×12',      category: 'bakery_dining', weightKg: 1.0, expiryTime: hoursFrom(18), photoUrl: null },
      { name: 'Pain au Chocolat ×8',      category: 'bakery_dining', weightKg: 0.8, expiryTime: hoursFrom(18), photoUrl: null },
    ],
    driverId: null, qrCode: 'batch_007', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },

  // ── claimed: driver_002 en route to Mövenpick Hotel ──────────────────────
  {
    id: 'batch_008', donorId: 'donor_003', donorName: 'Mövenpick Hotel Bangkok',
    donorContact: '+66812345603',
    pickupAddress: '672 Wireless Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId: 'ben_002', beneficiaryName: 'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'claimed', pickupWindowStart: '15:00', pickupWindowEnd: '16:00',
    specialInstructions: 'Afternoon high-tea leftovers. Bring cooler box.',
    items: [
      { name: 'Club Sandwiches ×12',  category: 'local_dining',  weightKg: 3.6, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Fresh Fruit Cups ×8',  category: 'local_dining',  weightKg: 1.6, expiryTime: hoursFrom(4), photoUrl: null },
      { name: 'Cheesecake Slices ×6', category: 'bakery_dining', weightKg: 0.9, expiryTime: hoursFrom(3), photoUrl: null },
    ],
    driverId: 'driver_002', qrCode: 'batch_008', claimedAt: hoursAgo(1), pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: daysAgo(1), updatedAt: hoursAgo(1),
  },

  // ── pickedUp: driver_001 in transit ──────────────────────────────────────
  {
    id: 'batch_009', donorId: 'donor_005', donorName: 'Bangkapi School Canteen',
    donorContact: '+66812345605',
    pickupAddress: '182 Ladprao 122, Wang Thonglang, Bangkok 10310',
    beneficiaryId: 'ben_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'pickedUp', pickupWindowStart: '12:30', pickupWindowEnd: '13:30',
    specialInstructions: 'Lunch leftover. Use main canteen side door.',
    items: [
      { name: 'Thai Basil Stir-Fry ×30', category: 'local_dining', weightKg: 6.0, expiryTime: hoursFrom(1),   photoUrl: null },
      { name: 'Steamed Rice ×30',        category: 'local_dining', weightKg: 9.0, expiryTime: hoursFrom(2),   photoUrl: null },
      { name: 'Clear Vegetable Soup',    category: 'local_dining', weightKg: 3.0, expiryTime: hoursFrom(1.5), photoUrl: null },
      { name: 'Fresh Pineapple Chunks',  category: 'local_dining', weightKg: 2.0, expiryTime: hoursFrom(4),   photoUrl: null },
    ],
    driverId: 'driver_001', qrCode: 'batch_009',
    claimedAt: hoursAgo(2), pickedUpAt: hoursAgo(0.5), deliveredAt: null,
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: hoursAgo(3), updatedAt: hoursAgo(0.5),
  },

  // ── delivered: Anchana Bakery history ────────────────────────────────────
  {
    id: 'batch_010', donorId: 'donor_004', donorName: 'Anchana Bakery & Café',
    donorContact: '+66812345604',
    pickupAddress: '55/3 Ramkhamhaeng Rd, Hua Mak, Bang Kapi, Bangkok 10240',
    beneficiaryId: 'ben_003', beneficiaryName: 'Prateep Foundation Elderly Care',
    beneficiaryAddress: '152/88 Sukhumvit Soi 26, Bangkok 10110',
    status: 'delivered', pickupWindowStart: '19:00', pickupWindowEnd: '20:00',
    specialInstructions: null,
    items: [
      { name: 'Whole Wheat Loaves ×6', category: 'bakery_dining', weightKg: 3.6, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Butter Cookies ×24',   category: 'bakery_dining', weightKg: 0.6, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Banana Bread ×3',      category: 'bakery_dining', weightKg: 0.9, expiryTime: daysAgo(0.5), photoUrl: null },
    ],
    driverId: 'driver_003', qrCode: 'batch_010',
    claimedAt: daysAgo(2), pickedUpAt: daysAgo(2), deliveredAt: daysAgo(2),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'Delivered to Prateep Foundation. 12 elderly residents received bread.',
    rating: 5, feedback: 'Fresh baked goods! The elderly residents loved it.',
    createdAt: daysAgo(2), updatedAt: daysAgo(2),
  },

  // ── delivered: 7-Eleven history ───────────────────────────────────────────
  {
    id: 'batch_011', donorId: 'donor_006', donorName: '7-Eleven Sukhumvit 11',
    donorContact: '+66812345606',
    pickupAddress: '11 Sukhumvit Soi 11, Khlong Toei Nuea, Watthana, Bangkok 10110',
    beneficiaryId: 'ben_004', beneficiaryName: 'Bangkapi Community Kitchen',
    beneficiaryAddress: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
    status: 'delivered', pickupWindowStart: '22:30', pickupWindowEnd: '23:30',
    specialInstructions: 'Near-expiry packaged foods. Supervisor: Khun Suphot.',
    items: [
      { name: 'Sandwiches near-expiry ×15', category: 'local_dining',  weightKg: 3.75, expiryTime: daysAgo(0.1), photoUrl: null },
      { name: 'Onigiri ×20',               category: 'local_dining',  weightKg: 2.0,  expiryTime: daysAgo(0.1), photoUrl: null },
    ],
    driverId: 'driver_002', qrCode: 'batch_011',
    claimedAt: daysAgo(1), pickedUpAt: daysAgo(1), deliveredAt: daysAgo(1),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'All items within expiry. Community kitchen confirmed 35 portions served.',
    rating: 4, feedback: 'Convenient late-night pickup. Great variety.',
    createdAt: daysAgo(1), updatedAt: daysAgo(1),
  },

  // ── cancelled: Central Embassy (no driver found in time) ─────────────────
  {
    id: 'batch_012', donorId: 'donor_002', donorName: 'Central Embassy Food Court',
    donorContact: '+66812345602',
    pickupAddress: '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId: 'ben_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'cancelled', pickupWindowStart: '22:00', pickupWindowEnd: '22:30',
    specialInstructions: null,
    items: [
      { name: 'Sushi Platter ×4', category: 'local_dining', weightKg: 2.4, expiryTime: daysAgo(1), photoUrl: null },
      { name: 'Miso Soup ×8',     category: 'local_dining', weightKg: 1.6, expiryTime: daysAgo(1), photoUrl: null },
    ],
    driverId: null, qrCode: 'batch_012', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: daysAgo(2), updatedAt: daysAgo(1),
  },
];
```

- [ ] **Step 4: Replace the IMPACT_METRICS constant**

Find and replace the entire `const IMPACT_METRICS = [...]` block with:

```js
// Metrics reflect delivered batches: batch_005 (donor_001), batch_010 (donor_004), batch_011 (donor_006).
const IMPACT_METRICS = [
  { id: 'donor_001', totalKg: 7.0,  totalMeals: 14, totalCO2e: 17.5, totalDeliveries: 1 },
  { id: 'donor_002', totalKg: 0.0,  totalMeals:  0, totalCO2e:  0.0, totalDeliveries: 0 },
  { id: 'donor_003', totalKg: 0.0,  totalMeals:  0, totalCO2e:  0.0, totalDeliveries: 0 },
  { id: 'donor_004', totalKg: 5.1,  totalMeals: 10, totalCO2e: 12.8, totalDeliveries: 1 },
  { id: 'donor_005', totalKg: 0.0,  totalMeals:  0, totalCO2e:  0.0, totalDeliveries: 0 },
  { id: 'donor_006', totalKg: 5.75, totalMeals: 11, totalCO2e: 14.4, totalDeliveries: 1 },
];
```

- [ ] **Step 5: Update the summary console.log in main()**

Find the summary block inside `main()` and replace it with:

```js
  console.log('\nSummary:');
  console.log(`  beneficiaries  : ${BENEFICIARIES.length}`);
  console.log(`  users          : ${USERS.length}  (6 donors · 3 drivers · 1 beneficiary)`);
  console.log(`  batches        : ${BATCHES.length}  (5 open · 2 claimed · 1 pickedUp · 3 delivered · 1 cancelled)`);
  console.log(`  impactMetrics  : ${IMPACT_METRICS.length}`);
  console.log('\nDone.\n');
```

- [ ] **Step 6: Syntax-check the file**

Run from `tools/seed/`:

```bash
node --check seed.js
```

Expected: no output (means no syntax errors). If there is output, fix the reported line.

- [ ] **Step 7: Commit**

```bash
git add tools/seed/seed.js
git commit -m "feat: expand seed data to 10 users, 4 beneficiaries, 12 batches, 6 impact metrics"
```

---

### Task 3: Smoke-test seed script against emulator (optional but recommended)

Skip this task if the Firebase emulator is not running.

**Files:** none (read-only verification)

- [ ] **Step 1: Start the Firebase emulator**

From the repo root (requires Firebase CLI: `npm install -g firebase-tools`):

```bash
firebase emulators:start --only firestore
```

Expected: `✔ All emulators ready! It is now safe to connect your app.`

- [ ] **Step 2: Run the seed script**

From `tools/seed/`:

```bash
node seed.js --emulator --clean
```

Expected output:

```
SaveAMeal seed script
Project : saveameal-87187
Target  : Firestore emulator (localhost:8080)
Mode    : clean + seed

Clearing existing data...
  ✗  cleared users (N docs)
  ✗  cleared batches (N docs)
  ...

Writing seed data...
  ✓  beneficiaries    4 documents
  ✓  users            10 documents
  ✓  batches          12 documents
  ✓  impactMetrics    6 documents

Summary:
  beneficiaries  : 4
  users          : 10  (6 donors · 3 drivers · 1 beneficiary)
  batches        : 12  (5 open · 2 claimed · 1 pickedUp · 3 delivered · 1 cancelled)
  impactMetrics  : 6

Done.
```

If the script exits with an error, check the line number it reports and fix the data in that batch/user entry.
