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
const keyIdx         = args.indexOf('--key');
const keyPath        = keyIdx >= 0 ? args[keyIdx + 1] : null;
const addDriverIdx   = args.indexOf('--add-driver');
const addDriverUid   = addDriverIdx >= 0 ? args[addDriverIdx + 1] : null;
const addDonorIdx    = args.indexOf('--add-donor');
const addDonorUid    = addDonorIdx >= 0 ? args[addDonorIdx + 1] : null;

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
// Fields: id (String), name (String), address (String?)
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
];

// Collection: users/{uid}
// Fields match UserModel — role values: 'donor' | 'driver' | 'beneficiary'
//            status values (beneficiary only): 'accepting' | 'full'
const USERS = [
  // ── Donors ────────────────────────────────────────────────────────────────
  {
    uid:     'donor_001',
    name:    'Somchai Kamolrat',
    email:   'somchai@srisilom.co.th',
    role:    'donor',
    phone:   '+66812345601',
    orgName: 'Sri Silom Restaurant',
    status:  null,
    points:  0,
  },
  {
    uid:     'donor_002',
    name:    'Naree Wongkasem',
    email:   'naree@centralembassy.th',
    role:    'donor',
    phone:   '+66812345602',
    orgName: 'Central Embassy Food Court',
    status:  null,
    points:  0,
  },

  // ── Drivers ───────────────────────────────────────────────────────────────
  {
    uid:     'driver_001',
    name:    'Krit Chaiwong',
    email:   'krit.chaiwong@saveameal.th',
    role:    'driver',
    phone:   '+66812345611',
    orgName: null,
    status:  null,
    points:  120,
  },
  {
    uid:     'driver_002',
    name:    'Amporn Suwan',
    email:   'amporn.suwan@saveameal.th',
    role:    'driver',
    phone:   '+66812345612',
    orgName: null,
    status:  null,
    points:  80,
  },

  // ── Beneficiary user ──────────────────────────────────────────────────────
  {
    uid:     'bene_user_001',
    name:    'Wanchai Thongsuk',
    email:   'wanchai@baansaengtawan.org',
    role:    'beneficiary',
    phone:   '+66812345620',
    orgName: 'Baan Saeng Tawan Shelter',
    status:  'accepting',
    points:  0,
  },
];

// Collection: batches/{id}
// Fields match BatchModel.
// status values: 'open' | 'claimed' | 'pickedUp' | 'delivered' | 'closed'
//   (from _$BatchStatusEnumMap in batch_model.g.dart — note 'pickedUp' not 'picked_up')
// items[] matches BatchItemModel — category is a Material icon name string
const BATCHES = [
  // ── open: Sri Silom → Baan Saeng Tawan ────────────────────────────────────
  {
    id:                 'batch_001',
    donorId:            'donor_001',
    donorName:          'Sri Silom Restaurant',
    donorContact:       '+66812345601',
    pickupAddress:      '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    beneficiaryId:      'ben_001',
    beneficiaryName:    'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status:             'open',
    pickupWindowStart:  '14:00',
    pickupWindowEnd:    '16:00',
    specialInstructions: 'Please bring insulated bags. Ask for Khun Somchai at reception.',
    items: [
      { name: 'Pad Thai',           category: 'local_dining',  weightKg: 3.0, expiryTime: hoursFrom(6),  photoUrl: null },
      { name: 'Tom Kha Soup',       category: 'local_dining',  weightKg: 2.5, expiryTime: hoursFrom(6),  photoUrl: null },
      { name: 'Jasmine Rice',       category: 'local_dining',  weightKg: 4.0, expiryTime: hoursFrom(8),  photoUrl: null },
      { name: 'Mango Sticky Rice',  category: 'bakery_dining', weightKg: 1.5, expiryTime: hoursFrom(4),  photoUrl: null },
    ],
    driverId:        null,
    qrCode:          'batch_001',
    claimedAt:       null,
    pickedUpAt:      null,
    deliveredAt:     null,
    photoUrl:        null,
    pickupPhotoUrl:  null,
    deliveryNotes:   null,
    rating:          null,
    feedback:        null,
    createdAt:       iso(now),
    updatedAt:       iso(now),
  },

  // ── open: Central Embassy → Klongtoey ─────────────────────────────────────
  {
    id:                 'batch_002',
    donorId:            'donor_002',
    donorName:          'Central Embassy Food Court',
    donorContact:       '+66812345602',
    pickupAddress:      '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId:      'ben_002',
    beneficiaryName:    'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status:             'open',
    pickupWindowStart:  '21:00',
    pickupWindowEnd:    '22:30',
    specialInstructions: 'Closing time pickup. Use staff entrance on the left side.',
    items: [
      { name: 'Margherita Pizza ×6 slices', category: 'local_pizza',  weightKg: 1.8, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Caesar Salad',               category: 'local_dining', weightKg: 0.9, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Croissant ×8',               category: 'bakery_dining',weightKg: 0.6, expiryTime: hoursFrom(18),photoUrl: null },
    ],
    driverId:        null,
    qrCode:          'batch_002',
    claimedAt:       null,
    pickedUpAt:      null,
    deliveredAt:     null,
    photoUrl:        null,
    pickupPhotoUrl:  null,
    deliveryNotes:   null,
    rating:          null,
    feedback:        null,
    createdAt:       iso(now),
    updatedAt:       iso(now),
  },

  // ── open: Sri Silom → Klongtoey ───────────────────────────────────────────
  {
    id:                 'batch_003',
    donorId:            'donor_001',
    donorName:          'Sri Silom Restaurant',
    donorContact:       '+66812345601',
    pickupAddress:      '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    beneficiaryId:      'ben_002',
    beneficiaryName:    'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status:             'open',
    pickupWindowStart:  '19:00',
    pickupWindowEnd:    '20:30',
    specialInstructions: null,
    items: [
      { name: 'Green Curry (large)',  category: 'local_dining', weightKg: 3.5, expiryTime: hoursFrom(6), photoUrl: null },
      { name: 'Som Tum Salad',        category: 'local_dining', weightKg: 1.2, expiryTime: hoursFrom(4), photoUrl: null },
    ],
    driverId:        null,
    qrCode:          'batch_003',
    claimedAt:       null,
    pickedUpAt:      null,
    deliveredAt:     null,
    photoUrl:        null,
    pickupPhotoUrl:  null,
    deliveryNotes:   null,
    rating:          null,
    feedback:        null,
    createdAt:       iso(now),
    updatedAt:       iso(now),
  },

  // ── claimed: driver_001 en route to pickup ─────────────────────────────────
  {
    id:                 'batch_004',
    donorId:            'donor_002',
    donorName:          'Central Embassy Food Court',
    donorContact:       '+66812345602',
    pickupAddress:      '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId:      'ben_001',
    beneficiaryName:    'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status:             'claimed',
    pickupWindowStart:  '18:00',
    pickupWindowEnd:    '19:00',
    specialInstructions: 'Handle with care — soup containers. Driver should call first.',
    items: [
      { name: 'Tom Yum Soup ×10 portions',  category: 'local_dining', weightKg: 5.0, expiryTime: hoursFrom(3), photoUrl: null },
      { name: 'Khao Man Gai ×8 portions',   category: 'local_dining', weightKg: 4.0, expiryTime: hoursFrom(3), photoUrl: null },
    ],
    driverId:        'driver_001',
    qrCode:          'batch_004',
    claimedAt:       hoursAgo(0.5),
    pickedUpAt:      null,
    deliveredAt:     null,
    photoUrl:        null,
    pickupPhotoUrl:  null,
    deliveryNotes:   null,
    rating:          null,
    feedback:        null,
    createdAt:       daysAgo(1),
    updatedAt:       hoursAgo(0.5),
  },

  // ── delivered: history record ──────────────────────────────────────────────
  {
    id:                 'batch_005',
    donorId:            'donor_001',
    donorName:          'Sri Silom Restaurant',
    donorContact:       '+66812345601',
    pickupAddress:      '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    beneficiaryId:      'ben_002',
    beneficiaryName:    'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status:             'delivered',
    pickupWindowStart:  '14:00',
    pickupWindowEnd:    '15:30',
    specialInstructions: null,
    items: [
      { name: 'Fried Rice family size', category: 'local_dining', weightKg: 4.0, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Spring Rolls ×12',       category: 'local_dining', weightKg: 1.0, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Fruit Platter',          category: 'local_dining', weightKg: 2.0, expiryTime: daysAgo(0.5), photoUrl: null },
    ],
    driverId:        'driver_002',
    qrCode:          'batch_005',
    claimedAt:       daysAgo(1),
    pickedUpAt:      daysAgo(1),
    deliveredAt:     daysAgo(1),
    photoUrl:        null,
    pickupPhotoUrl:  'https://placehold.co/600x400/png',
    deliveryNotes:   'All items delivered in good condition. Shelter staff confirmed.',
    rating:          5,
    feedback:        'Great rescue! Food was still warm.',
    createdAt:       daysAgo(1),
    updatedAt:       daysAgo(1),
  },
];

// Collection: impactMetrics/{donorId}
// Written by Cloud Functions in production; seeded here for UI testing.
// Fields match ImpactMetricsModel.
const IMPACT_METRICS = [
  {
    id:               'donor_001',
    totalKg:          7.0,
    totalMeals:       3,
    totalCO2e:        10.5,
    totalDeliveries:  1,
  },
  {
    id:               'donor_002',
    totalKg:          0.0,
    totalMeals:       0,
    totalCO2e:        0.0,
    totalDeliveries:  0,
  },
];

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
  await db.collection('users').doc(uid).set({
    uid,
    name,
    email: `${role}_${uid.slice(0, 6)}@dev.local`,
    role,
    phone: null,
    orgName: role === 'donor' ? `${name} Org` : null,
    status: role === 'beneficiary' ? 'accepting' : null,
    points: 0,
  }, { merge: true });
  console.log(`  ✓  registered ${role}: ${uid} (${name})`);
}

async function main() {
  console.log('\nSaveAMeal seed script');
  console.log(`Project : saveameal-87187`);
  console.log(`Target  : ${useEmulator ? 'Firestore emulator (localhost:8080)' : 'live Firestore'}`);

  // ── Quick-register a real Firebase Auth UID without wiping seed data ──────
  if (addDriverUid) {
    await registerUser(addDriverUid, 'driver', 'Dev Driver');
    return;
  }
  if (addDonorUid) {
    await registerUser(addDonorUid, 'donor', 'Dev Donor');
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

  console.log('\nSummary:');
  console.log(`  beneficiaries  : ${BENEFICIARIES.length}`);
  console.log(`  users          : ${USERS.length}  (2 donors · 2 drivers · 1 beneficiary)`);
  console.log(`  batches        : ${BATCHES.length}  (3 open · 1 claimed · 1 delivered)`);
  console.log(`  impactMetrics  : ${IMPACT_METRICS.length}`);
  console.log('\nDone.\n');
}

main().catch((err) => {
  console.error('\n✗ Seed failed:', err.message);
  process.exit(1);
});
