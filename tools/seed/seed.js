/**
 * SaveAMeal — Firestore seed script
 * Project: saveameal-87187
 *
 * Usage:
 *   # Against the local Firebase Emulator (recommended for dev)
 *   npm run seed              — write seed data
 *   npm run seed:clean        — wipe existing seed data then write
 *
 *   # Against live Firestore (requires a service account key)
 *   npm run seed:prod         — write seed data
 *   npm run seed:prod:clean   — wipe then write
 *
 * How to get a service account key (for live Firestore):
 *   1. Go to https://console.firebase.google.com/project/saveameal-87187/settings/serviceaccounts/adminsdk
 *   2. Click "Generate new private key"
 *   3. Save the file as  tools/seed/serviceAccountKey.json
 *   4. Never commit that file (it is in .gitignore)
 *
 * How to start the Firebase Emulator:
 *   firebase emulators:start --only firestore
 */

'use strict';

const admin = require('firebase-admin');
const path  = require('path');

// ── CLI flags ──────────────────────────────────────────────────────────────────

const args           = process.argv.slice(2);
const useEmulator    = args.includes('--emulator');
const cleanFirst     = args.includes('--clean');
const demoMode       = args.includes('--demo');
const keyIdx         = args.indexOf('--key');
const keyPath        = keyIdx >= 0 ? args[keyIdx + 1] : null;
const addDriverIdx      = args.indexOf('--add-driver');
const addDriverUid      = addDriverIdx >= 0 ? args[addDriverIdx + 1] : null;
const addDonorIdx       = args.indexOf('--add-donor');
const addDonorUid       = addDonorIdx >= 0 ? args[addDonorIdx + 1] : null;
const addBeneficiaryIdx = args.indexOf('--add-beneficiary');
const addBeneficiaryUid = addBeneficiaryIdx >= 0 ? args[addBeneficiaryIdx + 1] : null;
const seedLeaderboardIdx = args.indexOf('--seed-leaderboard');
const seedLeaderboardUid = seedLeaderboardIdx >= 0 ? args[seedLeaderboardIdx + 1] : null;

// ── Initialise Firebase ────────────────────────────────────────────────────────

if (useEmulator) {
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
  admin.initializeApp({ projectId: 'saveameal-87187' });
} else {
  if (!keyPath) {
    console.error(
      '\nERROR: Must supply --key or --emulator.\n\n' +
      'Options:\n' +
      '  node seed.js --emulator             (writes to local Firestore emulator)\n' +
      '  node seed.js --key serviceAccountKey.json  (writes to live Firestore)\n'
    );
    process.exit(1);
  }
  admin.initializeApp({
    credential: admin.credential.cert(require(path.resolve(keyPath))),
  });
}

const db = admin.firestore();

// ── Time helpers ───────────────────────────────────────────────────────────────
// DateTime fields are stored as ISO-8601 strings to match the Dart Freezed
// models (batch_model.g.dart uses DateTime.parse / toIso8601String).

const now       = new Date();
const iso       = (d) => d.toISOString();
const hoursAgo  = (h) => iso(new Date(now - h * 3600000));
const hoursFrom = (h) => iso(new Date(now.getTime() + h * 3600000));
const daysAgo   = (d) => iso(new Date(now - d * 86400000));

// ── Seed data ──────────────────────────────────────────────────────────────────

// Collection: beneficiaries/{id}
// Fields: id (String), name (String), address (String?), lat (Number?), lng (Number?)
const BENEFICIARIES = [
  {
    id:      'ben_001',
    name:    'Baan Saeng Tawan Shelter',
    address: '12 Lat Phrao Soi 15, Chankasem, Chatuchak, Bangkok 10230',
    lat:     13.8102,
    lng:     100.5699,
  },
  {
    id:      'ben_002',
    name:    'Klongtoey Community Center',
    address: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    lat:     13.7246,
    lng:     100.5235,
  },
  {
    id:      'ben_003',
    name:    'Prateep Foundation Elderly Care',
    address: '152/88 Sukhumvit Soi 26, Khlong Toei, Bangkok 10110',
    lat:     13.7197,
    lng:     100.5663,
  },
  {
    id:      'ben_004',
    name:    'Bangkapi Community Kitchen',
    address: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
    lat:     13.7814,
    lng:     100.5956,
  },
];

// Collection: users/{uid}
// Fields match UserModel — role values: 'donor' | 'driver' | 'beneficiary'
//            status values (beneficiary only): 'accepting' | 'full'
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
    mealsSaved: 512, sproutPoints: 2048,
    rank: 1, totalDrivers: 128,
    rankProgressCurrent: 512, rankProgressTarget: 750,
    currentRankName: 'Silver', nextRankName: 'Gold',
  },
  {
    uid: 'driver_002', name: 'Amporn Suwan',
    email: 'amporn.suwan@saveameal.th', role: 'driver',
    phone: '+66812345612', orgName: null, status: null, points: 280,
    mealsSaved: 489, sproutPoints: 1956,
    rank: 2, totalDrivers: 128,
    rankProgressCurrent: 489, rankProgressTarget: 750,
    currentRankName: 'Silver', nextRankName: 'Gold',
  },
  {
    uid: 'driver_003', name: 'Montri Phansiri',
    email: 'montri.phansiri@saveameal.th', role: 'driver',
    phone: '+66812345613', orgName: null, status: null, points: 150,
    mealsSaved: 420, sproutPoints: 1680,
    rank: 3, totalDrivers: 128,
    rankProgressCurrent: 420, rankProgressTarget: 750,
    currentRankName: 'Silver', nextRankName: 'Gold',
  },

  // ── Beneficiary ───────────────────────────────────────────────────────────
  {
    uid: 'bene_user_001', name: 'Wanchai Thongsuk',
    email: 'wanchai@baansaengtawan.org', role: 'beneficiary',
    phone: '+66812345620', orgName: 'Baan Saeng Tawan Shelter',
    status: 'accepting', points: 0,
  },
];

// Collection: batches/{id}
// Fields match BatchModel.
// status values: 'open' | 'claimed' | 'pickedUp' | 'delivered' | 'closed'
//   (from _$BatchStatusEnumMap in batch_model.g.dart — note 'pickedUp' not 'picked_up')
// items[] matches BatchItemModel — category is a Material icon name string
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

  // ── delivered: history (Sri Silom) ───────────────────────────────────────
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
      { name: 'Bread Rolls ×20',               category: 'bakery_dining', weightKg: 2.0, expiryTime: hoursFrom(24), photoUrl: null },
      { name: 'Fresh Salad Assorted',          category: 'local_dining',  weightKg: 1.5, expiryTime: hoursFrom(3),  photoUrl: null },
      { name: 'Fruit Station Platter',         category: 'local_dining',  weightKg: 3.0, expiryTime: hoursFrom(6),  photoUrl: null },
      { name: 'Cheese & Cold Cuts',            category: 'local_dining',  weightKg: 1.0, expiryTime: hoursFrom(4),  photoUrl: null },
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
      { name: 'Sourdough Loaves ×4',   category: 'bakery_dining', weightKg: 2.4, expiryTime: hoursFrom(20), photoUrl: null },
      { name: 'Almond Croissants ×10', category: 'bakery_dining', weightKg: 1.2, expiryTime: hoursFrom(18), photoUrl: null },
      { name: 'Danish Pastries ×12',   category: 'bakery_dining', weightKg: 1.0, expiryTime: hoursFrom(18), photoUrl: null },
      { name: 'Pain au Chocolat ×8',   category: 'bakery_dining', weightKg: 0.8, expiryTime: hoursFrom(18), photoUrl: null },
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
      { name: 'Sandwiches near-expiry ×15', category: 'local_dining', weightKg: 3.75, expiryTime: daysAgo(0.1), photoUrl: null },
      { name: 'Onigiri ×20',               category: 'local_dining', weightKg: 2.0,  expiryTime: daysAgo(0.1), photoUrl: null },
    ],
    driverId: 'driver_002', qrCode: 'batch_011',
    claimedAt: daysAgo(1), pickedUpAt: daysAgo(1), deliveredAt: daysAgo(1),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'All items within expiry. Community kitchen confirmed 35 portions served.',
    rating: 4, feedback: 'Convenient late-night pickup. Great variety.',
    createdAt: daysAgo(1), updatedAt: daysAgo(1),
  },

  // ── cancelled ─────────────────────────────────────────────────────────────
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

// Collection: impactMetrics/{donorId}
// Written by Cloud Functions in production; seeded here for UI testing.
// Fields match ImpactMetricsModel.
// Metrics reflect delivered batches: batch_005 (donor_001), batch_010 (donor_004), batch_011 (donor_006).
const IMPACT_METRICS = [
  { id: 'donor_001', totalKg: 7.0,  totalMeals: 14, totalCO2e: 17.5, totalDeliveries: 1 },
  { id: 'donor_002', totalKg: 0.0,  totalMeals:  0, totalCO2e:  0.0, totalDeliveries: 0 },
  { id: 'donor_003', totalKg: 0.0,  totalMeals:  0, totalCO2e:  0.0, totalDeliveries: 0 },
  { id: 'donor_004', totalKg: 5.1,  totalMeals: 10, totalCO2e: 12.8, totalDeliveries: 1 },
  { id: 'donor_005', totalKg: 0.0,  totalMeals:  0, totalCO2e:  0.0, totalDeliveries: 0 },
  { id: 'donor_006', totalKg: 5.75, totalMeals: 11, totalCO2e: 14.4, totalDeliveries: 1 },
];

// Collection: leaderboard/{period}
// Single document per period with an `entries` array.
// The `uid` field must match a real users/{uid} for the (You) highlight to work.
const LEADERBOARD = {
  thisMonth: {
    entries: [
      { rank: 1, uid: 'driver_001', driverName: 'Krit C.',   zone: 'Central Hub',    score: 512, avatarUrl: '' },
      { rank: 2, uid: 'driver_002', driverName: 'Amporn S.', zone: 'North District', score: 489, avatarUrl: '' },
      { rank: 3, uid: 'driver_003', driverName: 'Montri P.', zone: 'East Side',      score: 420, avatarUrl: '' },
    ],
  },
};

// ── Demo setup ─────────────────────────────────────────────────────────────────
//
// Creates the three demo Firebase Auth accounts (donor / driver / beneficiary),
// registers them in Firestore, and seeds a ready-to-use demo batch.
// Safe to run multiple times — uses merge: true and getUserByEmail to avoid
// duplicates if accounts already exist.

const DEMO_ACCOUNTS = [
  {
    email:   'demo.donor@saveameal.th',
    password: 'qwer1234',
    role:    'donor',
    name:    'Khun Siriporn',
    orgName: 'FreshMart Supermarket',
  },
  {
    email:   'demo.driver@saveameal.th',
    password: 'qwer1234',
    role:    'driver',
    name:    'Nattapong',
    orgName: null,
  },
  {
    email:   'demo.beneficiary@saveameal.th',
    password: 'qwer1234',
    role:    'beneficiary',
    name:    'Sister Maria',
    orgName: 'Klongtoey Community Center',
  },
];

async function getOrCreateAuthUser({ email, password, name }) {
  try {
    const existing = await admin.auth().getUserByEmail(email);
    console.log(`  ~  Auth account already exists: ${email}  (${existing.uid})`);
    return existing;
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      const created = await admin.auth().createUser({ email, password, displayName: name });
      console.log(`  ✓  Created Auth account: ${email}  (${created.uid})`);
      return created;
    }
    throw e;
  }
}

async function setupDemo() {
  console.log('\nSetting up demo accounts and seed data...\n');

  const uids = {};

  for (const acc of DEMO_ACCOUNTS) {
    const authUser = await getOrCreateAuthUser(acc);
    uids[acc.role] = authUser.uid;

    const driverImpactFields = acc.role === 'driver' ? {
      mealsSaved: 342, sproutPoints: 1250,
      rank: 4, totalDrivers: 128,
      rankProgressCurrent: 342, rankProgressTarget: 500,
      currentRankName: 'Bronze', nextRankName: 'Silver',
    } : {};

    await db.collection('users').doc(authUser.uid).set({
      uid:     authUser.uid,
      name:    acc.name,
      email:   acc.email,
      role:    acc.role,
      phone:   null,
      orgName: acc.orgName,
      status:  acc.role === 'beneficiary' ? 'accepting' : null,
      points:  0,
      ...driverImpactFields,
    }, { merge: true });
    console.log(`  ✓  users/${authUser.uid}  (${acc.role}: ${acc.name})`);
  }

  // beneficiaries collection entry (needed for intake status + tracking map)
  await db.collection('beneficiaries').doc(uids.beneficiary).set({
    id:           uids.beneficiary,
    name:         'Sister Maria Shelter',
    address:      '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    lat:          13.7246,
    lng:          100.5235,
    intakeStatus: 'accepting',
  }, { merge: true });
  console.log(`  ✓  beneficiaries/${uids.beneficiary}`);

  // Empty impact metrics so the donor dashboard shows clean zeros on first login
  await db.collection('impactMetrics').doc(uids.donor).set({
    id:               uids.donor,
    totalKg:          0.0,
    totalMeals:       0,
    totalCO2e:        0.0,
    totalDeliveries:  0,
  }, { merge: true });
  console.log(`  ✓  impactMetrics/${uids.donor}  (zeroed)`);

  // Demo batch — open, tied to real Auth UIDs so accept-job + notifications work
  const batchId  = 'demo_batch_001';
  const batchNow = new Date();
  const expiryTs = new Date(batchNow.getTime() + 8 * 3600000).toISOString();

  await db.collection('batches').doc(batchId).set({
    id:                  batchId,
    donorId:             uids.donor,
    donorName:           'FreshMart Supermarket',
    donorContact:        null,
    pickupAddress:       '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId:       uids.beneficiary,
    beneficiaryName:     'Sister Maria Shelter',
    beneficiaryAddress:  '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status:              'open',
    pickupWindowStart:   '21:00',
    pickupWindowEnd:     '22:30',
    specialInstructions: 'Demo batch. Ask for Khun Siriporn at the service entrance.',
    items: [
      {
        name:       'Cooked Meals Assortment',
        category:   'other',
        weightKg:   15.2,
        expiryTime: expiryTs,
        photoUrl:   null,
      },
    ],
    driverId:        null,
    qrCode:          batchId,
    claimedAt:       null,
    pickedUpAt:      null,
    deliveredAt:     null,
    photoUrl:        null,
    pickupPhotoUrl:  null,
    deliveryNotes:   null,
    rating:          null,
    feedback:        null,
    createdAt:       batchNow.toISOString(),
    updatedAt:       batchNow.toISOString(),
  });
  console.log(`  ✓  batches/${batchId}  (status: open)`);

  // Leaderboard — demo driver appears at rank 4 with their real UID
  await db.collection('leaderboard').doc('thisMonth').set({
    entries: [
      { rank: 1, uid: 'driver_001',   driverName: 'Sarah J.',   zone: 'Central Hub',    score: 512, avatarUrl: '' },
      { rank: 2, uid: 'driver_002',   driverName: 'Marcus T.',  zone: 'North District', score: 489, avatarUrl: '' },
      { rank: 3, uid: 'driver_003',   driverName: 'Elena R.',   zone: 'East Side',      score: 420, avatarUrl: '' },
      { rank: 4, uid: uids.driver,    driverName: 'Nattapong',  zone: 'South Zone',     score: 342, avatarUrl: '' },
    ],
  });
  console.log(`  ✓  leaderboard/thisMonth  (demo driver at rank 4)`);

  console.log('\n─────────────────────────────────────────────────────────');
  console.log('Demo ready! Login credentials:\n');
  console.log(`  Donor       demo.donor@saveameal.th        / qwer1234`);
  console.log(`  Driver      demo.driver@saveameal.th       / qwer1234`);
  console.log(`  Beneficiary demo.beneficiary@saveameal.th  / qwer1234`);
  console.log('\nFirestore UIDs:');
  console.log(`  Donor       ${uids.donor}`);
  console.log(`  Driver      ${uids.driver}`);
  console.log(`  Beneficiary ${uids.beneficiary}`);
  console.log('\nDemo batch: demo_batch_001  (QR code: demo_batch_001)');
  console.log('─────────────────────────────────────────────────────────\n');
}

// ── Firestore batch-write helpers ──────────────────────────────────────────────

async function writeAll(collectionName, docs, idField = 'id') {
  const batch = db.batch();
  for (const doc of docs) {
    batch.set(db.collection(collectionName).doc(doc[idField]), doc);
  }
  await batch.commit();
  console.log(`  ✓  ${collectionName.padEnd(16)} ${docs.length} documents`);
}

async function clearCollection(collectionName) {
  const snap = await db.collection(collectionName).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  console.log(`  ✗  cleared ${collectionName} (${snap.size} docs)`);
}

// ── Main ───────────────────────────────────────────────────────────────────────

async function registerUser(uid, role, name) {
  const driverImpactFields = role === 'driver' ? {
    mealsSaved: 0, sproutPoints: 0,
    rank: 0, totalDrivers: 0,
    rankProgressCurrent: 0, rankProgressTarget: 100,
    currentRankName: 'Bronze', nextRankName: 'Silver',
  } : {};
  await db.collection('users').doc(uid).set({
    uid,
    name,
    email: `${role}_${uid.slice(0, 6)}@dev.local`,
    role,
    phone: null,
    orgName: role === 'donor' ? `${name} Org` : null,
    status: role === 'beneficiary' ? 'accepting' : null,
    points: 0,
    ...driverImpactFields,
  }, { merge: true });
  console.log(`  ✓  registered ${role}: ${uid} (${name})`);
}

async function main() {
  console.log('\nSaveAMeal seed script');
  console.log(`Project : saveameal-87187`);
  console.log(`Target  : ${useEmulator ? 'Firestore emulator (localhost:8080)' : 'live Firestore'}`);

  // ── Demo mode: create Auth accounts + seed demo batch in one shot ─────────
  if (demoMode) {
    await setupDemo();
    return;
  }

  // ── Write leaderboard/thisMonth with your UID at rank 4 ──────────────────
  if (seedLeaderboardUid) {
    await db.collection('leaderboard').doc('thisMonth').set({
      entries: [
        { rank: 1, uid: 'fake-uid-1', driverName: 'Sarah J.',   zone: 'Central Hub',    score: 512, avatarUrl: '' },
        { rank: 2, uid: 'fake-uid-2', driverName: 'Marcus T.',  zone: 'North District', score: 489, avatarUrl: '' },
        { rank: 3, uid: 'fake-uid-3', driverName: 'Elena R.',   zone: 'East Side',      score: 420, avatarUrl: '' },
        { rank: 4, uid: seedLeaderboardUid, driverName: 'Nattapong', zone: 'South Zone', score: 342, avatarUrl: '' },
      ],
    });
    console.log(`\n  ✓  leaderboard/thisMonth written`);
    console.log(`     Your UID (${seedLeaderboardUid}) is at rank 4 — you will see the (You) highlight.\n`);
    return;
  }

  // ── Quick-register a real Firebase Auth UID without wiping seed data ──────
  if (addDriverUid) {
    await registerUser(addDriverUid, 'driver', 'Dev Driver');
    return;
  }
  if (addDonorUid) {
    await registerUser(addDonorUid, 'donor', 'Dev Donor');
    return;
  }
  if (addBeneficiaryUid) {
    // Creates both the users doc (for login) and the beneficiaries doc (for
    // intake status + tracking). The UID is used as BOTH document IDs so that
    // BeneficiaryDashboardScreen can look up deliveries by Auth UID.
    await registerUser(addBeneficiaryUid, 'beneficiary', 'Demo Shelter');
    await db.collection('beneficiaries').doc(addBeneficiaryUid).set({
      id:      addBeneficiaryUid,
      name:    'Demo Shelter',
      address: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
      lat:     13.7246,
      lng:     100.5235,
      intakeStatus: 'accepting',
    }, { merge: true });
    console.log(`  ✓  beneficiaries/${addBeneficiaryUid} created (Klongtoey coords)`);
    console.log(`\n  IMPORTANT: seed any demo batches with beneficiaryId: '${addBeneficiaryUid}'`);
    return;
  }

  if (cleanFirst) console.log('Mode    : clean + seed\n');
  else            console.log('Mode    : seed (merge into existing)\n');

  if (cleanFirst) {
    console.log('Clearing existing data...');
    await clearCollection('users');
    await clearCollection('batches');
    await clearCollection('beneficiaries');
    await clearCollection('impactMetrics');
    console.log();
  }

  console.log('Writing seed data...');
  await writeAll('beneficiaries', BENEFICIARIES);
  await writeAll('users',         USERS,          'uid');
  await writeAll('batches',       BATCHES);
  await writeAll('impactMetrics', IMPACT_METRICS);
  await db.collection('leaderboard').doc('thisMonth').set(LEADERBOARD.thisMonth);
  console.log(`  ✓  leaderboard       1 document  (thisMonth)`);

  console.log('\nSummary:');
  console.log(`  beneficiaries  : ${BENEFICIARIES.length}`);
  console.log(`  users          : ${USERS.length}  (6 donors · 3 drivers · 1 beneficiary)`);
  console.log(`  batches        : ${BATCHES.length}  (5 open · 2 claimed · 1 pickedUp · 3 delivered · 1 cancelled)`);
  console.log(`  impactMetrics  : ${IMPACT_METRICS.length}`);
  console.log(`  leaderboard    : 1  (thisMonth)`);
  console.log('\nDone.\n');
}

main().catch((err) => {
  console.error('\n✗ Seed failed:', err.message);
  process.exit(1);
});
