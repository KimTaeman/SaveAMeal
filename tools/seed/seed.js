/**
 * SaveAMeal — Firestore seed script
 * Project: saveameal-87187
 *
 * Usage:
 *   npm run seed              — write seed data (emulator)
 *   npm run seed:clean        — wipe then write (emulator)
 *   npm run seed:prod         — write seed data (live)
 *   npm run seed:prod:clean   — wipe then write (live)
 *
 * One-shot helpers:
 *   node seed.js --key KEY --demo                      create 3 demo Auth accounts + batch
 *   node seed.js --key KEY --add-driver <uid>          register existing UID as driver
 *   node seed.js --key KEY --add-donor <uid>           register existing UID as donor
 *   node seed.js --key KEY --add-beneficiary <uid>     register existing UID as beneficiary
 *   node seed.js --key KEY --seed-leaderboard <uid>    write leaderboard with your UID at rank 5
 */

'use strict';

const admin = require('firebase-admin');
const path  = require('path');

// ── CLI flags ──────────────────────────────────────────────────────────────────

const args              = process.argv.slice(2);
const useEmulator       = args.includes('--emulator');
const cleanFirst        = args.includes('--clean');
const demoMode          = args.includes('--demo');
const keyIdx            = args.indexOf('--key');
const keyPath           = keyIdx >= 0 ? args[keyIdx + 1] : null;
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
      '  node seed.js --emulator\n' +
      '  node seed.js --key serviceAccountKey.json\n'
    );
    process.exit(1);
  }
  admin.initializeApp({ credential: admin.credential.cert(require(path.resolve(keyPath))) });
}

const db = admin.firestore();

// ── Time helpers ───────────────────────────────────────────────────────────────
const now       = new Date();
const iso       = (d) => d.toISOString();
const hoursAgo  = (h) => iso(new Date(now - h * 3600000));
const hoursFrom = (h) => iso(new Date(now.getTime() + h * 3600000));
const daysAgo   = (d) => iso(new Date(now - d * 86400000));

// ── Seed data ──────────────────────────────────────────────────────────────────

// Collection: beneficiaries/{id}
// intakeStatus: 'accepting' | 'full'
// orgType: 'Shelter' | 'Food Bank' | 'Community Kitchen' | 'School' | 'Other'
const BENEFICIARIES = [
  {
    id: 'ben_001', name: 'Baan Saeng Tawan Shelter',
    address: '12 Lat Phrao Soi 15, Chankasem, Chatuchak, Bangkok 10230',
    lat: 13.8102, lng: 100.5699, intakeStatus: 'accepting',
    orgType: 'Shelter', contactEmail: 'info@baansaengtawan.org',
    missionStatement: 'Providing shelter, meals, and support to at-risk families in Bangkok.',
  },
  {
    id: 'ben_002', name: 'Klongtoey Community Center',
    address: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    lat: 13.7246, lng: 100.5235, intakeStatus: 'accepting',
    orgType: 'Community Kitchen', contactEmail: 'klongtoey@community.org',
    missionStatement: 'Serving hot meals daily to 300+ residents of the Klongtoey community.',
  },
  {
    id: 'ben_003', name: 'Prateep Foundation Elderly Care',
    address: '152/88 Sukhumvit Soi 26, Khlong Toei, Bangkok 10110',
    lat: 13.7197, lng: 100.5663, intakeStatus: 'full',
    orgType: 'Shelter', contactEmail: 'elderly@prateep.org',
    missionStatement: 'Caring for elderly residents who cannot care for themselves.',
  },
  {
    id: 'ben_004', name: 'Bangkapi Community Kitchen',
    address: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
    lat: 13.7814, lng: 100.5956, intakeStatus: 'accepting',
    orgType: 'Community Kitchen', contactEmail: 'bangkapi@kitchen.org',
    missionStatement: 'Daily meals for working families and street vendors in Bangkapi.',
  },
  {
    id: 'ben_005', name: 'Wat Phra Dhamma School Canteen',
    address: '72 Phetchaburi Rd, Ratchathewi, Bangkok 10400',
    lat: 13.7546, lng: 100.5329, intakeStatus: 'accepting',
    orgType: 'School', contactEmail: 'canteen@watphradhamma.ac.th',
    missionStatement: 'Ensuring every student at our monastery school receives a nutritious lunch.',
  },
  {
    id: 'ben_006', name: 'Sukhumvit Food Bank',
    address: '45/2 Sukhumvit Soi 8, Khlong Toei Nuea, Bangkok 10110',
    lat: 13.7402, lng: 100.5536, intakeStatus: 'accepting',
    orgType: 'Food Bank', contactEmail: 'sukhumvit.foodbank@gmail.com',
    missionStatement: 'Redistributing surplus food to 200+ families weekly in central Bangkok.',
  },
  {
    id: 'ben_007', name: 'Thai Red Cross Society Food Program',
    address: '1871 Rama IV Rd, Pathumwan, Bangkok 10330',
    lat: 13.7225, lng: 100.5275, intakeStatus: 'accepting',
    orgType: 'Food Bank', contactEmail: 'foodprogram@redcross.or.th',
    missionStatement: 'Emergency food assistance and daily nutrition support across Bangkok.',
<<<<<<< HEAD
  },
  // Beneficiary user document — keyed by user UID so watchActiveDeliveriesForBeneficiary()
  // and watchIntakeAvailability() resolve correctly when bene_user_001 is logged in.
  {
    id:           'bene_user_001',
    name:         'Baan Saeng Tawan Shelter',
    address:      '12 Lat Phrao Soi 15, Chankasem, Chatuchak, Bangkok 10230',
    lat:          13.8102,
    lng:          100.5699,
    intakeStatus: 'accepting',
=======
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
  },
];

// Collection: users/{uid}
// items[].category must match FoodCategory enum: bakery|produce|dairy|meat|beverages|other
const USERS = [
  // ── Donors (8) ────────────────────────────────────────────────────────────
  { uid: 'donor_001', name: 'Somchai Kamolrat',  email: 'somchai@srisilom.co.th',          role: 'donor', phone: '+66812345601', orgName: 'Sri Silom Restaurant',        status: null, points: 0 },
  { uid: 'donor_002', name: 'Naree Wongkasem',   email: 'naree@centralembassy.th',          role: 'donor', phone: '+66812345602', orgName: 'Central Embassy Food Court',  status: null, points: 0 },
  { uid: 'donor_003', name: 'Prasert Jaidee',    email: 'prasert@movenpick-bkk.com',        role: 'donor', phone: '+66812345603', orgName: 'Mövenpick Hotel Bangkok',      status: null, points: 0 },
  { uid: 'donor_004', name: 'Anchana Burin',     email: 'anchana@anchanabakery.th',         role: 'donor', phone: '+66812345604', orgName: 'Anchana Bakery & Café',       status: null, points: 0 },
  { uid: 'donor_005', name: 'Theerawat Sombat',  email: 'theerawat@bangkapi-school.go.th', role: 'donor', phone: '+66812345605', orgName: 'Bangkapi School Canteen',     status: null, points: 0 },
  { uid: 'donor_006', name: 'Suphot Rattana',    email: 'suphot@711sukhumvit.th',           role: 'donor', phone: '+66812345606', orgName: '7-Eleven Sukhumvit 11',       status: null, points: 0 },
  { uid: 'donor_007', name: 'Kanokwan Panya',    email: 'kanokwan@emporium-bkk.th',        role: 'donor', phone: '+66812345607', orgName: 'Emporium Supermarket',         status: null, points: 0 },
  { uid: 'donor_008', name: 'Weerayuth Sangoon', email: 'weerayuth@radissonblu.th',        role: 'donor', phone: '+66812345608', orgName: 'Radisson Blu Plaza Bangkok',   status: null, points: 0 },

  // ── Drivers (8) — ranked by mealsSaved ───────────────────────────────────
  {
    uid: 'driver_001', name: 'Krit Chaiwong', email: 'krit.chaiwong@saveameal.th',
    role: 'driver', phone: '+66812345611', status: null, points: 1520,
    vehicleType: 'Honda PCX 150', licensePlate: 'กข 1234', vehicleColor: 'White',
    cargoCapacity: 'Medium', primaryLocation: 'Silom', totalPickups: 52, joinDate: '01 Jan 2025',
    mealsSaved: 1520, sproutPoints: 6080, rank: 1, totalDrivers: 8,
    rankProgressCurrent: 520, rankProgressTarget: 1000, currentRankName: 'Gold', nextRankName: 'Master',
  },
  {
    uid: 'driver_002', name: 'Amporn Suwan', email: 'amporn.suwan@saveameal.th',
    role: 'driver', phone: '+66812345612', status: null, points: 1280,
    vehicleType: 'Yamaha NMAX 155', licensePlate: 'งจ 5678', vehicleColor: 'Blue',
    cargoCapacity: 'Medium', primaryLocation: 'Ploenchit', totalPickups: 44, joinDate: '15 Jan 2025',
    mealsSaved: 1280, sproutPoints: 5120, rank: 2, totalDrivers: 8,
    rankProgressCurrent: 280, rankProgressTarget: 1000, currentRankName: 'Gold', nextRankName: 'Master',
  },
  {
    uid: 'driver_003', name: 'Montri Phansiri', email: 'montri.phansiri@saveameal.th',
    role: 'driver', phone: '+66812345613', status: null, points: 980,
    vehicleType: 'Toyota Vios', licensePlate: 'ฉช 9012', vehicleColor: 'Silver',
    cargoCapacity: 'Large', primaryLocation: 'Sukhumvit', totalPickups: 34, joinDate: '01 Feb 2025',
    mealsSaved: 980, sproutPoints: 3920, rank: 3, totalDrivers: 8,
    rankProgressCurrent: 980, rankProgressTarget: 1000, currentRankName: 'Silver', nextRankName: 'Gold',
  },
  {
    uid: 'driver_004', name: 'Siriporn Chaisri', email: 'siriporn.chaisri@saveameal.th',
    role: 'driver', phone: '+66812345614', status: null, points: 750,
    vehicleType: 'Honda Click 125', licensePlate: 'ซฌ 3456', vehicleColor: 'Red',
    cargoCapacity: 'Small', primaryLocation: 'Chatuchak', totalPickups: 26, joinDate: '15 Feb 2025',
    mealsSaved: 750, sproutPoints: 3000, rank: 4, totalDrivers: 8,
    rankProgressCurrent: 250, rankProgressTarget: 500, currentRankName: 'Silver', nextRankName: 'Gold',
  },
  {
    uid: 'driver_005', name: 'Nattapong Wiset', email: 'nattapong.wiset@saveameal.th',
    role: 'driver', phone: '+66812345615', status: null, points: 580,
    vehicleType: 'Isuzu D-Max', licensePlate: 'ญฎ 7890', vehicleColor: 'Black',
    cargoCapacity: 'Extra Large', refrigeratedStorage: true,
    primaryLocation: 'South Zone', totalPickups: 20, joinDate: '01 Mar 2025',
    mealsSaved: 580, sproutPoints: 2320, rank: 5, totalDrivers: 8,
    rankProgressCurrent: 80, rankProgressTarget: 500, currentRankName: 'Silver', nextRankName: 'Gold',
  },
  {
    uid: 'driver_006', name: 'Prasoet Kanjanaporn', email: 'prasoet.kanjanaporn@saveameal.th',
    role: 'driver', phone: '+66812345616', status: null, points: 420,
    vehicleType: 'Honda Wave 110', licensePlate: 'ฐฑ 2345', vehicleColor: 'Green',
    cargoCapacity: 'Small', primaryLocation: 'Ladprao', totalPickups: 15, joinDate: '15 Mar 2025',
    mealsSaved: 420, sproutPoints: 1680, rank: 6, totalDrivers: 8,
    rankProgressCurrent: 420, rankProgressTarget: 500, currentRankName: 'Bronze', nextRankName: 'Silver',
  },
  {
    uid: 'driver_007', name: 'Wanida Somchai', email: 'wanida.somchai@saveameal.th',
    role: 'driver', phone: '+66812345617', status: null, points: 280,
    vehicleType: 'Yamaha Mio 125', licensePlate: 'ฒณ 6789', vehicleColor: 'Pink',
    cargoCapacity: 'Small', primaryLocation: 'Ramkhamhaeng', totalPickups: 10, joinDate: '01 Apr 2025',
    mealsSaved: 280, sproutPoints: 1120, rank: 7, totalDrivers: 8,
    rankProgressCurrent: 280, rankProgressTarget: 500, currentRankName: 'Bronze', nextRankName: 'Silver',
  },
  {
    uid: 'driver_008', name: 'Chalerm Nakapon', email: 'chalerm.nakapon@saveameal.th',
    role: 'driver', phone: '+66812345618', status: null, points: 150,
    vehicleType: 'Honda CBR 150', licensePlate: 'ดต 0123', vehicleColor: 'Orange',
    cargoCapacity: 'Small', primaryLocation: 'Bang Na', totalPickups: 5, joinDate: '15 Apr 2025',
    mealsSaved: 150, sproutPoints: 600, rank: 8, totalDrivers: 8,
    rankProgressCurrent: 150, rankProgressTarget: 500, currentRankName: 'Bronze', nextRankName: 'Silver',
  },

  // ── Beneficiary user (uid maps to beneficiaries/bene_user_001) ────────────
  {
    uid: 'bene_user_001', name: 'Wanchai Thongsuk',
    email: 'wanchai@baansaengtawan.org', role: 'beneficiary',
    phone: '+66812345620', orgName: 'Baan Saeng Tawan Shelter',
    status: 'accepting', points: 0,
  },
];

// Collection: batches/{id}
// status: 'open' | 'claimed' | 'pickedUp' | 'delivered' | 'cancelled'
// items[].category: bakery | produce | dairy | meat | beverages | other
const BATCHES = [

  // ── OPEN (4) ──────────────────────────────────────────────────────────────
  {
    id: 'batch_001', donorId: 'donor_001', donorName: 'Sri Silom Restaurant',
    pickupAddress: '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    pickupLat: 13.7247, pickupLng: 100.5199,
    beneficiaryId: 'ben_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'open', pickupWindowStart: '14:00', pickupWindowEnd: '16:00',
    specialInstructions: 'Insulated bags required. Ask for Khun Somchai at reception.',
    items: [
      { name: 'Pad Thai (20 portions)',    category: 'meat',    weightKg: 4.0, expiryTime: hoursFrom(6), photoUrl: null },
      { name: 'Jasmine Rice',              category: 'other',   weightKg: 5.0, expiryTime: hoursFrom(8), photoUrl: null },
      { name: 'Stir-Fried Vegetables',     category: 'produce', weightKg: 2.5, expiryTime: hoursFrom(5), photoUrl: null },
    ],
    driverId: null, qrCode: 'saveameal://batch/batch_001', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },
  {
    id: 'batch_002', donorId: 'donor_003', donorName: 'Mövenpick Hotel Bangkok',
    pickupAddress: '672 Wireless Rd, Lumphini, Pathumwan, Bangkok 10330',
    pickupLat: 13.7399, pickupLng: 100.5549,
    beneficiaryId: 'ben_002', beneficiaryName: 'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'open', pickupWindowStart: '22:00', pickupWindowEnd: '23:00',
    specialInstructions: 'After-dinner buffet. Use loading bay on Soi 30.',
    items: [
      { name: 'Buffet Assorted (hot)',   category: 'meat',    weightKg: 6.0, expiryTime: hoursFrom(3), photoUrl: null },
      { name: 'Bread Rolls ×24',        category: 'bakery',  weightKg: 1.5, expiryTime: hoursFrom(20), photoUrl: null },
      { name: 'Salad Station Assorted', category: 'produce', weightKg: 2.0, expiryTime: hoursFrom(3), photoUrl: null },
      { name: 'Fruit Platter',          category: 'produce', weightKg: 2.5, expiryTime: hoursFrom(6), photoUrl: null },
    ],
    driverId: null, qrCode: 'saveameal://batch/batch_002', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },
  {
    id: 'batch_003', donorId: 'donor_007', donorName: 'Emporium Supermarket',
    pickupAddress: '622 Sukhumvit Rd, Khlong Toei, Bangkok 10110',
    pickupLat: 13.7264, pickupLng: 100.5694,
    beneficiaryId: 'ben_006', beneficiaryName: 'Sukhumvit Food Bank',
    beneficiaryAddress: '45/2 Sukhumvit Soi 8, Bangkok 10110',
    status: 'open', pickupWindowStart: '20:00', pickupWindowEnd: '21:00',
    specialInstructions: 'Near-expiry items from the fresh section. Dock at Level B1.',
    items: [
      { name: 'Fresh Produce Mix',       category: 'produce',   weightKg: 8.0, expiryTime: hoursFrom(24), photoUrl: null },
      { name: 'Yoghurt & Dairy',         category: 'dairy',     weightKg: 3.0, expiryTime: hoursFrom(48), photoUrl: null },
      { name: 'Packaged Sandwiches ×20', category: 'other',     weightKg: 4.0, expiryTime: hoursFrom(6),  photoUrl: null },
      { name: 'Fruit Juice ×12',        category: 'beverages', weightKg: 6.0, expiryTime: hoursFrom(72), photoUrl: null },
    ],
    driverId: null, qrCode: 'saveameal://batch/batch_003', claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },
  {
    id: 'batch_004', donorId: 'donor_004', donorName: 'Anchana Bakery & Café',
    pickupAddress: '55/3 Ramkhamhaeng Rd, Hua Mak, Bang Kapi, Bangkok 10240',
    pickupLat: 13.7575, pickupLng: 100.6239,
    beneficiaryId: 'bene_user_001', beneficiaryName: 'Wat Phra Dhamma School Canteen',
    beneficiaryAddress: '72 Phetchaburi Rd, Ratchathewi, Bangkok 10400',
    status: 'open', pickupWindowStart: '18:30', pickupWindowEnd: '19:30',
    specialInstructions: 'End-of-day bakery surplus. Ring doorbell — ask for Khun Anchana.',
    items: [
      { name: 'Sourdough Loaves ×5',   category: 'bakery', weightKg: 3.0, expiryTime: hoursFrom(24), photoUrl: null },
      { name: 'Almond Croissants ×12', category: 'bakery', weightKg: 1.4, expiryTime: hoursFrom(18), photoUrl: null },
      { name: 'Danish Pastries ×15',   category: 'bakery', weightKg: 1.2, expiryTime: hoursFrom(18), photoUrl: null },
    ],
<<<<<<< HEAD
    driverId: null, qrCode: 'saveameal://batch/batch_004', claimedAt: null, pickedUpAt: null,
=======
    driverId: null, qrCode: 'batch_004', claimedAt: null, pickedUpAt: null,
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: iso(now), updatedAt: iso(now),
  },

  // ── CLAIMED (3) ───────────────────────────────────────────────────────────
  {
    id: 'batch_005', donorId: 'donor_002', donorName: 'Central Embassy Food Court',
    pickupAddress: '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    pickupLat: 13.7432, pickupLng: 100.5494,
    beneficiaryId: 'ben_003', beneficiaryName: 'Prateep Foundation Elderly Care',
    beneficiaryAddress: '152/88 Sukhumvit Soi 26, Bangkok 10110',
    status: 'claimed', pickupWindowStart: '21:00', pickupWindowEnd: '22:00',
    specialInstructions: 'Closing time. Use staff entrance left side.',
    items: [
      { name: 'Pasta & Noodles ×15', category: 'other', weightKg: 3.5, expiryTime: hoursFrom(2),  photoUrl: null },
      { name: 'Caesar Salad',        category: 'produce', weightKg: 1.2, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Croissants ×10',      category: 'bakery',  weightKg: 0.8, expiryTime: hoursFrom(16), photoUrl: null },
    ],
    driverId: 'driver_001', volunteerName: 'Krit Chaiwong',
    qrCode: 'saveameal://batch/batch_005', claimedAt: hoursAgo(0.5), pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: hoursAgo(2), updatedAt: hoursAgo(0.5),
  },
  {
    id: 'batch_006', donorId: 'donor_006', donorName: '7-Eleven Sukhumvit 11',
    pickupAddress: '11 Sukhumvit Soi 11, Khlong Toei Nuea, Watthana, Bangkok 10110',
    pickupLat: 13.7427, pickupLng: 100.5548,
    beneficiaryId: 'ben_004', beneficiaryName: 'Bangkapi Community Kitchen',
    beneficiaryAddress: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
    status: 'claimed', pickupWindowStart: '22:30', pickupWindowEnd: '23:30',
    specialInstructions: 'Near-expiry packaged foods. Supervisor: Khun Suphot.',
    items: [
      { name: 'Sandwiches near-expiry ×18', category: 'other',   weightKg: 4.5, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Onigiri ×24',               category: 'other',   weightKg: 2.4, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Milk ×6 cartons',           category: 'dairy',   weightKg: 3.0, expiryTime: hoursFrom(24), photoUrl: null },
    ],
    driverId: 'driver_004', volunteerName: 'Siriporn Chaisri',
    qrCode: 'saveameal://batch/batch_006', claimedAt: hoursAgo(1), pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: hoursAgo(3), updatedAt: hoursAgo(1),
  },
  {
    id: 'batch_007', donorId: 'donor_005', donorName: 'Bangkapi School Canteen',
    pickupAddress: '182 Ladprao 122, Wang Thonglang, Bangkok 10310',
    pickupLat: 13.7814, pickupLng: 100.5956,
    beneficiaryId: 'ben_007', beneficiaryName: 'Thai Red Cross Society Food Program',
    beneficiaryAddress: '1871 Rama IV Rd, Pathumwan, Bangkok 10330',
    status: 'claimed', pickupWindowStart: '13:00', pickupWindowEnd: '14:00',
    specialInstructions: 'Lunch surplus. Use main canteen side door.',
    items: [
      { name: 'Thai Stir-Fry ×25',    category: 'meat',    weightKg: 6.0, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Steamed Rice ×25',     category: 'other',   weightKg: 7.5, expiryTime: hoursFrom(3), photoUrl: null },
      { name: 'Vegetable Soup ×15',   category: 'produce', weightKg: 3.0, expiryTime: hoursFrom(2), photoUrl: null },
    ],
    driverId: 'driver_007', volunteerName: 'Wanida Somchai',
    qrCode: 'saveameal://batch/batch_007', claimedAt: hoursAgo(0.25), pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: hoursAgo(1), updatedAt: hoursAgo(0.25),
  },

  // ── PICKED UP (2) ─────────────────────────────────────────────────────────
  {
    id: 'batch_008', donorId: 'donor_008', donorName: 'Radisson Blu Plaza Bangkok',
    pickupAddress: '489 Sukhumvit Rd, Khlong Toei Nuea, Watthana, Bangkok 10110',
    pickupLat: 13.7395, pickupLng: 100.5616,
    beneficiaryId: 'bene_user_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'pickedUp', pickupWindowStart: '22:00', pickupWindowEnd: '23:00',
    specialInstructions: 'Hotel banquet leftovers. Security will let you in.',
    items: [
      { name: 'Banquet Canapés ×80',   category: 'other',   weightKg: 5.0, expiryTime: hoursFrom(1), photoUrl: null },
      { name: 'Sliced Beef ×30',       category: 'meat',    weightKg: 4.5, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Cheese & Bread Board',  category: 'dairy',   weightKg: 2.0, expiryTime: hoursFrom(4), photoUrl: null },
    ],
    driverId: 'driver_002', volunteerName: 'Amporn Suwan',
    qrCode: 'saveameal://batch/batch_008', claimedAt: hoursAgo(2), pickedUpAt: hoursAgo(0.5),
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: hoursAgo(3), updatedAt: hoursAgo(0.5),
  },
  {
    id: 'batch_009', donorId: 'donor_001', donorName: 'Sri Silom Restaurant',
<<<<<<< HEAD
=======
    donorContact: '+66812345601',
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
    pickupAddress: '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    pickupLat: 13.7247, pickupLng: 100.5199,
    beneficiaryId: 'bene_user_001', beneficiaryName: 'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'pickedUp', pickupWindowStart: '15:00', pickupWindowEnd: '16:00',
    specialInstructions: 'Afternoon surplus. Side entrance.',
    items: [
      { name: 'Green Curry ×20',   category: 'meat',    weightKg: 5.0, expiryTime: hoursFrom(2), photoUrl: null },
      { name: 'Som Tum Salad ×12', category: 'produce', weightKg: 1.8, expiryTime: hoursFrom(1), photoUrl: null },
      { name: 'Coconut Milk Soup', category: 'other',   weightKg: 3.0, expiryTime: hoursFrom(2), photoUrl: null },
    ],
    driverId: 'driver_005', volunteerName: 'Nattapong Wiset',
    qrCode: 'saveameal://batch/batch_009', claimedAt: hoursAgo(3), pickedUpAt: hoursAgo(1),
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: hoursAgo(4), updatedAt: hoursAgo(1),
  },

  // ── DELIVERED (9) — history for impact metrics & order history ─────────────
  {
    id: 'batch_010', donorId: 'donor_001', donorName: 'Sri Silom Restaurant',
    pickupAddress: '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    pickupLat: 13.7247, pickupLng: 100.5199,
    beneficiaryId: 'ben_002', beneficiaryName: 'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'delivered', pickupWindowStart: '14:00', pickupWindowEnd: '15:00',
    specialInstructions: null,
    items: [
      { name: 'Fried Rice ×30',       category: 'other',   weightKg: 7.0, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Pork Stir-Fry ×20',   category: 'meat',    weightKg: 4.0, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Mixed Vegetables ×15', category: 'produce', weightKg: 2.5, expiryTime: daysAgo(0.5), photoUrl: null },
    ],
    driverId: 'driver_001', volunteerName: 'Krit Chaiwong',
    qrCode: 'saveameal://batch/batch_010', claimedAt: daysAgo(1), pickedUpAt: daysAgo(1), deliveredAt: daysAgo(1),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'All items delivered in good condition.', rating: 5,
    feedback: 'Great rescue, food still warm!',
    createdAt: daysAgo(1), updatedAt: daysAgo(1),
  },
  {
    id: 'batch_011', donorId: 'donor_002', donorName: 'Central Embassy Food Court',
    pickupAddress: '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    pickupLat: 13.7432, pickupLng: 100.5494,
    beneficiaryId: 'ben_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'delivered', pickupWindowStart: '21:00', pickupWindowEnd: '22:00',
    specialInstructions: null,
    items: [
      { name: 'International Cuisine ×25', category: 'other',  weightKg: 5.0, expiryTime: daysAgo(1), photoUrl: null },
      { name: 'Sushi Assorted ×20',        category: 'other',  weightKg: 2.0, expiryTime: daysAgo(1), photoUrl: null },
      { name: 'Fruit Salad',               category: 'produce',weightKg: 1.4, expiryTime: daysAgo(1), photoUrl: null },
    ],
    driverId: 'driver_002', volunteerName: 'Amporn Suwan',
    qrCode: 'saveameal://batch/batch_011', claimedAt: daysAgo(1), pickedUpAt: daysAgo(1), deliveredAt: daysAgo(1),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'Delivered to shelter. 25 residents received food.',
    rating: 4, feedback: 'Variety of food, residents were happy.',
    createdAt: daysAgo(1), updatedAt: daysAgo(1),
  },
  {
    id: 'batch_012', donorId: 'donor_003', donorName: 'Mövenpick Hotel Bangkok',
<<<<<<< HEAD
=======
    donorContact: '+66812345603',
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
    pickupAddress: '672 Wireless Rd, Lumphini, Pathumwan, Bangkok 10330',
    pickupLat: 13.7399, pickupLng: 100.5549,
    beneficiaryId: 'ben_003', beneficiaryName: 'Prateep Foundation Elderly Care',
    beneficiaryAddress: '152/88 Sukhumvit Soi 26, Bangkok 10110',
    status: 'delivered', pickupWindowStart: '22:00', pickupWindowEnd: '23:00',
    specialInstructions: null,
    items: [
      { name: 'Buffet Mains ×30', category: 'meat',   weightKg: 8.0, expiryTime: daysAgo(1.5), photoUrl: null },
      { name: 'Dessert Station',  category: 'bakery', weightKg: 2.0, expiryTime: daysAgo(1.5), photoUrl: null },
      { name: 'Cold Cuts Board',  category: 'meat',   weightKg: 2.0, expiryTime: daysAgo(1.5), photoUrl: null },
    ],
    driverId: 'driver_003', volunteerName: 'Montri Phansiri',
    qrCode: 'saveameal://batch/batch_012', claimedAt: daysAgo(2), pickedUpAt: daysAgo(2), deliveredAt: daysAgo(2),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'Elderly residents very grateful.',
    rating: 5, feedback: 'Premium hotel food, wonderful quality.',
    createdAt: daysAgo(2), updatedAt: daysAgo(2),
  },
  {
    id: 'batch_013', donorId: 'donor_004', donorName: 'Anchana Bakery & Café',
<<<<<<< HEAD
=======
    donorContact: '+66812345604',
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
    pickupAddress: '55/3 Ramkhamhaeng Rd, Hua Mak, Bang Kapi, Bangkok 10240',
    pickupLat: 13.7575, pickupLng: 100.6239,
    beneficiaryId: 'ben_004', beneficiaryName: 'Bangkapi Community Kitchen',
    beneficiaryAddress: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
    status: 'delivered', pickupWindowStart: '19:00', pickupWindowEnd: '20:00',
    specialInstructions: null,
    items: [
      { name: 'Whole Wheat Loaves ×8', category: 'bakery', weightKg: 4.0, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Butter Cookies ×30',   category: 'bakery', weightKg: 0.9, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Banana Bread ×4',      category: 'bakery', weightKg: 1.2, expiryTime: daysAgo(0.5), photoUrl: null },
      { name: 'Fruit Tarts ×12',      category: 'bakery', weightKg: 1.4, expiryTime: daysAgo(0.5), photoUrl: null },
    ],
    driverId: 'driver_006', volunteerName: 'Prasoet Kanjanaporn',
    qrCode: 'saveameal://batch/batch_013', claimedAt: daysAgo(1), pickedUpAt: daysAgo(1), deliveredAt: daysAgo(1),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'Fresh baked goods, community was delighted.',
    rating: 5, feedback: 'Best bakery rescue so far!',
    createdAt: daysAgo(1), updatedAt: daysAgo(1),
  },
  {
    id: 'batch_014', donorId: 'donor_005', donorName: 'Bangkapi School Canteen',
    pickupAddress: '182 Ladprao 122, Wang Thonglang, Bangkok 10310',
    pickupLat: 13.7814, pickupLng: 100.5956,
    beneficiaryId: 'ben_005', beneficiaryName: 'Wat Phra Dhamma School Canteen',
    beneficiaryAddress: '72 Phetchaburi Rd, Ratchathewi, Bangkok 10400',
    status: 'delivered', pickupWindowStart: '12:30', pickupWindowEnd: '13:30',
    specialInstructions: null,
    items: [
      { name: 'Thai Basil Chicken ×35', category: 'meat',    weightKg: 8.0, expiryTime: daysAgo(2), photoUrl: null },
      { name: 'Steamed Rice ×35',       category: 'other',   weightKg: 10.0, expiryTime: daysAgo(2), photoUrl: null },
      { name: 'Pineapple Chunks',       category: 'produce', weightKg: 2.0, expiryTime: daysAgo(2), photoUrl: null },
    ],
    driverId: 'driver_003', volunteerName: 'Montri Phansiri',
    qrCode: 'saveameal://batch/batch_014', claimedAt: daysAgo(2), pickedUpAt: daysAgo(2), deliveredAt: daysAgo(2),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'School children received full meals.',
    rating: 5, feedback: 'School-to-school delivery, smooth and efficient.',
    createdAt: daysAgo(2), updatedAt: daysAgo(2),
  },
  {
    id: 'batch_015', donorId: 'donor_006', donorName: '7-Eleven Sukhumvit 11',
    pickupAddress: '11 Sukhumvit Soi 11, Khlong Toei Nuea, Watthana, Bangkok 10110',
    pickupLat: 13.7427, pickupLng: 100.5548,
    beneficiaryId: 'ben_002', beneficiaryName: 'Klongtoey Community Center',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'delivered', pickupWindowStart: '22:30', pickupWindowEnd: '23:30',
    specialInstructions: null,
    items: [
      { name: 'Sandwiches ×20',    category: 'other',   weightKg: 5.0, expiryTime: daysAgo(3), photoUrl: null },
      { name: 'Onigiri ×25',       category: 'other',   weightKg: 2.5, expiryTime: daysAgo(3), photoUrl: null },
      { name: 'Beverage Pack ×10', category: 'beverages', weightKg: 5.0, expiryTime: daysAgo(3), photoUrl: null },
    ],
    driverId: 'driver_001', volunteerName: 'Krit Chaiwong',
    qrCode: 'saveameal://batch/batch_015', claimedAt: daysAgo(3), pickedUpAt: daysAgo(3), deliveredAt: daysAgo(3),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: '45 portions served to community members.',
    rating: 4, feedback: 'Great variety from convenience store.',
    createdAt: daysAgo(3), updatedAt: daysAgo(3),
  },
  {
    id: 'batch_016', donorId: 'donor_007', donorName: 'Emporium Supermarket',
    pickupAddress: '622 Sukhumvit Rd, Khlong Toei, Bangkok 10110',
    pickupLat: 13.7264, pickupLng: 100.5694,
    beneficiaryId: 'ben_007', beneficiaryName: 'Thai Red Cross Society Food Program',
    beneficiaryAddress: '1871 Rama IV Rd, Pathumwan, Bangkok 10330',
    status: 'delivered', pickupWindowStart: '20:30', pickupWindowEnd: '21:30',
    specialInstructions: null,
    items: [
      { name: 'Fresh Vegetable Box',  category: 'produce', weightKg: 6.5, expiryTime: daysAgo(1), photoUrl: null },
      { name: 'Yoghurt & Milk',       category: 'dairy',   weightKg: 4.0, expiryTime: daysAgo(1), photoUrl: null },
    ],
    driverId: 'driver_004', volunteerName: 'Siriporn Chaisri',
    qrCode: 'saveameal://batch/batch_016', claimedAt: daysAgo(1), pickedUpAt: daysAgo(1), deliveredAt: daysAgo(1),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'High-quality fresh produce, 40 families served.',
    rating: 5, feedback: 'Excellent quality, families very thankful.',
    createdAt: daysAgo(1), updatedAt: daysAgo(1),
  },
  {
    id: 'batch_017', donorId: 'donor_008', donorName: 'Radisson Blu Plaza Bangkok',
    pickupAddress: '489 Sukhumvit Rd, Khlong Toei Nuea, Watthana, Bangkok 10110',
    pickupLat: 13.7395, pickupLng: 100.5616,
    beneficiaryId: 'ben_006', beneficiaryName: 'Sukhumvit Food Bank',
    beneficiaryAddress: '45/2 Sukhumvit Soi 8, Bangkok 10110',
    status: 'delivered', pickupWindowStart: '21:00', pickupWindowEnd: '22:00',
    specialInstructions: null,
    items: [
      { name: 'Conference Lunch Boxes ×40', category: 'other', weightKg: 10.0, expiryTime: daysAgo(4), photoUrl: null },
      { name: 'Mineral Water ×48',         category: 'beverages', weightKg: 24.0, expiryTime: daysAgo(4), photoUrl: null },
      { name: 'Assorted Pastries ×30',     category: 'bakery',   weightKg: 2.5, expiryTime: daysAgo(4), photoUrl: null },
    ],
    driverId: 'driver_002', volunteerName: 'Amporn Suwan',
    qrCode: 'saveameal://batch/batch_017', claimedAt: daysAgo(4), pickedUpAt: daysAgo(4), deliveredAt: daysAgo(4),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: '80+ meals distributed to food bank recipients.',
    rating: 5, feedback: 'Premium hotel quality, recipients were thrilled.',
    createdAt: daysAgo(4), updatedAt: daysAgo(4),
  },
  {
    id: 'batch_018', donorId: 'donor_001', donorName: 'Sri Silom Restaurant',
    pickupAddress: '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    pickupLat: 13.7247, pickupLng: 100.5199,
    beneficiaryId: 'ben_004', beneficiaryName: 'Bangkapi Community Kitchen',
    beneficiaryAddress: '45 Ladprao Rd, Wang Thonglang, Bangkok 10310',
    status: 'delivered', pickupWindowStart: '18:00', pickupWindowEnd: '19:00',
    specialInstructions: null,
    items: [
      { name: 'Tom Yum Soup ×20',    category: 'other',   weightKg: 6.0, expiryTime: daysAgo(5), photoUrl: null },
      { name: 'Khao Pad Gaprao ×20', category: 'meat',    weightKg: 5.5, expiryTime: daysAgo(5), photoUrl: null },
      { name: 'Papaya Salad ×15',    category: 'produce', weightKg: 1.8, expiryTime: daysAgo(5), photoUrl: null },
    ],
    driverId: 'driver_005', volunteerName: 'Nattapong Wiset',
    qrCode: 'saveameal://batch/batch_018', claimedAt: daysAgo(5), pickedUpAt: daysAgo(5), deliveredAt: daysAgo(5),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'Community kitchen served 55 evening meals.',
    rating: 5, feedback: 'Authentic Thai food, perfectly timed.',
    createdAt: daysAgo(5), updatedAt: daysAgo(5),
  },

  // ── CANCELLED (1) ─────────────────────────────────────────────────────────
  {
    id: 'batch_019', donorId: 'donor_002', donorName: 'Central Embassy Food Court',
<<<<<<< HEAD
=======
    donorContact: '+66812345602',
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
    pickupAddress: '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    beneficiaryId: 'ben_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'cancelled', pickupWindowStart: '22:00', pickupWindowEnd: '22:30',
    specialInstructions: null,
    items: [
      { name: 'Cold Buffet Assorted', category: 'other', weightKg: 4.0, expiryTime: daysAgo(2), photoUrl: null },
      { name: 'Sushi Platter',        category: 'other', weightKg: 2.4, expiryTime: daysAgo(2), photoUrl: null },
    ],
<<<<<<< HEAD
    driverId: null, qrCode: 'saveameal://batch/batch_019', claimedAt: null, pickedUpAt: null,
=======
    driverId: null, qrCode: 'batch_x01', claimedAt: null, pickedUpAt: null,
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: daysAgo(3), updatedAt: daysAgo(2),
  },
<<<<<<< HEAD

  // ── closed: beneficiary confirmed receipt ────────────────────────────────
  {
    id: 'batch_013_closed', donorId: 'donor_001', donorName: 'Sri Silom Restaurant',
    pickupAddress: '28/4 Silom Rd, Bang Rak, Bangkok 10500',
    pickupLat: 13.7247, pickupLng: 100.5199,
    beneficiaryId: 'bene_user_001', beneficiaryName: 'Baan Saeng Tawan Shelter',
    beneficiaryAddress: '12 Lat Phrao Soi 15, Bangkok 10230',
    status: 'closed', pickupWindowStart: '13:00', pickupWindowEnd: '14:00',
    specialInstructions: null,
    items: [
      { name: 'Khao Pad (Fried Rice) ×20', category: 'other',   weightKg: 4.0, expiryTime: daysAgo(3), photoUrl: null },
      { name: 'Pineapple Chunks',          category: 'produce', weightKg: 1.5, expiryTime: daysAgo(3), photoUrl: null },
      { name: 'Dinner Rolls ×10',          category: 'bakery',  weightKg: 0.8, expiryTime: daysAgo(3), photoUrl: null },
    ],
    driverId: 'driver_001', qrCode: 'saveameal://batch/batch_013',
    claimedAt: daysAgo(3), pickedUpAt: daysAgo(3), deliveredAt: daysAgo(3),
    photoUrl: null, pickupPhotoUrl: 'https://placehold.co/600x400/png',
    deliveryNotes: 'Delivered in good condition. Shelter staff confirmed receipt.',
    rating: 5, feedback: 'Great service!',
    createdAt: daysAgo(3), updatedAt: daysAgo(3),
  },
];

// Collection: driverLocations/{driverId}
// Fields match DriverLocationModel — used by beneficiary tracking screen.
// driver_001 is seeded in-transit (batch_009 is pickedUp) roughly between
// Bangkapi School (13.7575, 100.6239) and Baan Saeng Tawan (13.8102, 100.5699).
const DRIVER_LOCATIONS = [
  {
    driverId:  'driver_001',
    lat:       13.7850,
    lng:       100.5920,
    updatedAt: null, // populated at write time
  },
];

=======
];

>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
// Collection: impactMetrics/{id}
// totalKg = sum of delivered batch item weights
// totalMeals ≈ totalKg * 2, totalCO2e ≈ totalKg * 2.5
const IMPACT_METRICS = [
  { id: 'donor_001', totalKg: 44.8, totalMeals: 90,  totalCO2e: 112.0, totalDeliveries: 3 },
  { id: 'donor_002', totalKg:  8.4, totalMeals: 17,  totalCO2e:  21.0, totalDeliveries: 1 },
  { id: 'donor_003', totalKg: 12.0, totalMeals: 24,  totalCO2e:  30.0, totalDeliveries: 1 },
  { id: 'donor_004', totalKg:  7.5, totalMeals: 15,  totalCO2e:  18.8, totalDeliveries: 1 },
  { id: 'donor_005', totalKg: 20.0, totalMeals: 40,  totalCO2e:  50.0, totalDeliveries: 1 },
  { id: 'donor_006', totalKg: 12.5, totalMeals: 25,  totalCO2e:  31.3, totalDeliveries: 1 },
  { id: 'donor_007', totalKg: 10.5, totalMeals: 21,  totalCO2e:  26.3, totalDeliveries: 1 },
  { id: 'donor_008', totalKg: 36.5, totalMeals: 73,  totalCO2e:  91.3, totalDeliveries: 2 },
];

// Collection: leaderboard/thisMonth
// Entries match USERS driver mealsSaved values exactly.
const LEADERBOARD = {
  thisMonth: {
    entries: [
      { rank: 1, uid: 'driver_001', driverName: 'Krit C.',      zone: 'Silom',         score: 1520, avatarUrl: '' },
      { rank: 2, uid: 'driver_002', driverName: 'Amporn S.',    zone: 'Ploenchit',     score: 1280, avatarUrl: '' },
      { rank: 3, uid: 'driver_003', driverName: 'Montri P.',    zone: 'Sukhumvit',     score: 980,  avatarUrl: '' },
      { rank: 4, uid: 'driver_004', driverName: 'Siriporn C.',  zone: 'Chatuchak',     score: 750,  avatarUrl: '' },
      { rank: 5, uid: 'driver_005', driverName: 'Nattapong W.', zone: 'South Zone',    score: 580,  avatarUrl: '' },
      { rank: 6, uid: 'driver_006', driverName: 'Prasoet K.',   zone: 'Ladprao',       score: 420,  avatarUrl: '' },
      { rank: 7, uid: 'driver_007', driverName: 'Wanida S.',    zone: 'Ramkhamhaeng', score: 280,  avatarUrl: '' },
      { rank: 8, uid: 'driver_008', driverName: 'Chalerm N.',   zone: 'Bang Na',       score: 150,  avatarUrl: '' },
    ],
  },
};

// ── Demo setup ─────────────────────────────────────────────────────────────────

const DEMO_ACCOUNTS = [
  { email: 'demo.donor@saveameal.th',       password: 'qwer1234', role: 'donor',       name: 'Khun Siriporn', orgName: 'FreshMart Supermarket'       },
  { email: 'demo.driver@saveameal.th',      password: 'qwer1234', role: 'driver',      name: 'Nattapong',     orgName: null                          },
  { email: 'demo.beneficiary@saveameal.th', password: 'qwer1234', role: 'beneficiary', name: 'Sister Maria',  orgName: 'Klongtoey Community Center'  },
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
      mealsSaved: 580, sproutPoints: 2320,
      rank: 5, totalDrivers: 8,
      rankProgressCurrent: 80, rankProgressTarget: 500,
      currentRankName: 'Silver', nextRankName: 'Gold',
    } : {};

    await db.collection('users').doc(authUser.uid).set({
      uid: authUser.uid, name: acc.name, email: acc.email, role: acc.role,
      phone: null, orgName: acc.orgName,
      status: acc.role === 'beneficiary' ? 'accepting' : null,
      points: 0, ...driverImpactFields,
    }, { merge: true });
    console.log(`  ✓  users/${authUser.uid}  (${acc.role}: ${acc.name})`);
  }

  await db.collection('beneficiaries').doc(uids.beneficiary).set({
    id: uids.beneficiary, name: 'Sister Maria Shelter',
    address: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    lat: 13.7246, lng: 100.5235, intakeStatus: 'accepting',
    orgType: 'Shelter', contactEmail: 'demo.beneficiary@saveameal.th',
    missionStatement: 'Demo shelter for SaveAMeal testing.',
  }, { merge: true });
  console.log(`  ✓  beneficiaries/${uids.beneficiary}`);

  await db.collection('impactMetrics').doc(uids.donor).set({
    id: uids.donor, totalKg: 0.0, totalMeals: 0, totalCO2e: 0.0, totalDeliveries: 0,
  }, { merge: true });
  console.log(`  ✓  impactMetrics/${uids.donor}  (zeroed)`);

  const batchId  = 'demo_batch_001';
  const batchNow = new Date();
  await db.collection('batches').doc(batchId).set({
<<<<<<< HEAD
    id:                  batchId,
    donorId:             uids.donor,
    donorName:           'FreshMart Supermarket',
    pickupAddress:       '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    pickupLat:           13.7432,
    pickupLng:           100.5494,
    beneficiaryId:       uids.beneficiary,
    beneficiaryName:     'Sister Maria Shelter',
    beneficiaryAddress:  '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status:              'open',
    pickupWindowStart:   '21:00',
    pickupWindowEnd:     '22:30',
=======
    id: batchId, donorId: uids.donor, donorName: 'FreshMart Supermarket',
    donorContact: null,
    pickupAddress: '1031 Ploenchit Rd, Lumphini, Pathumwan, Bangkok 10330',
    pickupLat: 13.7432, pickupLng: 100.5494,
    beneficiaryId: uids.beneficiary, beneficiaryName: 'Sister Maria Shelter',
    beneficiaryAddress: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
    status: 'open', pickupWindowStart: '21:00', pickupWindowEnd: '22:30',
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
    specialInstructions: 'Demo batch. Ask for Khun Siriporn at the service entrance.',
    items: [
      { name: 'Fresh Produce Mix',     category: 'produce', weightKg: 5.0,  expiryTime: new Date(batchNow.getTime() + 24*3600000).toISOString(), photoUrl: null },
      { name: 'Bakery Assorted ×12',   category: 'bakery',  weightKg: 1.5,  expiryTime: new Date(batchNow.getTime() + 18*3600000).toISOString(), photoUrl: null },
      { name: 'Cooked Meal Boxes ×10', category: 'other',   weightKg: 8.0,  expiryTime: new Date(batchNow.getTime() +  6*3600000).toISOString(), photoUrl: null },
    ],
<<<<<<< HEAD
    driverId:        null,
    qrCode:          `saveameal://batch/${batchId}`,
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
=======
    driverId: null, qrCode: batchId, claimedAt: null, pickedUpAt: null,
    deliveredAt: null, photoUrl: null, pickupPhotoUrl: null,
    deliveryNotes: null, rating: null, feedback: null,
    createdAt: batchNow.toISOString(), updatedAt: batchNow.toISOString(),
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
  });
  console.log(`  ✓  batches/${batchId}  (status: open, 3 items)`);

  await db.collection('leaderboard').doc('thisMonth').set({
    entries: [
      { rank: 1, uid: 'driver_001', driverName: 'Krit C.',      zone: 'Silom',         score: 1520, avatarUrl: '' },
      { rank: 2, uid: 'driver_002', driverName: 'Amporn S.',    zone: 'Ploenchit',     score: 1280, avatarUrl: '' },
      { rank: 3, uid: 'driver_003', driverName: 'Montri P.',    zone: 'Sukhumvit',     score: 980,  avatarUrl: '' },
      { rank: 4, uid: 'driver_004', driverName: 'Siriporn C.',  zone: 'Chatuchak',     score: 750,  avatarUrl: '' },
      { rank: 5, uid: uids.driver,  driverName: 'Nattapong',    zone: 'South Zone',    score: 580,  avatarUrl: '' },
      { rank: 6, uid: 'driver_006', driverName: 'Prasoet K.',   zone: 'Ladprao',       score: 420,  avatarUrl: '' },
      { rank: 7, uid: 'driver_007', driverName: 'Wanida S.',    zone: 'Ramkhamhaeng', score: 280,  avatarUrl: '' },
      { rank: 8, uid: 'driver_008', driverName: 'Chalerm N.',   zone: 'Bang Na',       score: 150,  avatarUrl: '' },
    ],
  });
  console.log(`  ✓  leaderboard/thisMonth  (demo driver at rank 5)`);

  console.log('\n─────────────────────────────────────────────────────────');
  console.log('Demo ready! Login credentials:\n');
  console.log(`  Donor       demo.donor@saveameal.th        / qwer1234`);
  console.log(`  Driver      demo.driver@saveameal.th       / qwer1234`);
  console.log(`  Beneficiary demo.beneficiary@saveameal.th  / qwer1234`);
  console.log('\nFirestore UIDs:');
  console.log(`  Donor       ${uids.donor}`);
  console.log(`  Driver      ${uids.driver}`);
  console.log(`  Beneficiary ${uids.beneficiary}`);
  console.log('\nDemo batch: demo_batch_001  (QR code: saveameal://batch/demo_batch_001)');
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
    mealsSaved: 0, sproutPoints: 0, rank: 0, totalDrivers: 0,
    rankProgressCurrent: 0, rankProgressTarget: 100,
    currentRankName: 'Bronze', nextRankName: 'Silver',
  } : {};
  await db.collection('users').doc(uid).set({
    uid, name,
    email: `${role}_${uid.slice(0, 6)}@dev.local`,
    role, phone: null,
    orgName: role === 'donor' ? `${name} Org` : null,
    status: role === 'beneficiary' ? 'accepting' : null,
    points: 0, ...driverImpactFields,
  }, { merge: true });
  console.log(`  ✓  registered ${role}: ${uid} (${name})`);
}

async function main() {
  console.log('\nSaveAMeal seed script');
  console.log(`Project : saveameal-87187`);
  console.log(`Target  : ${useEmulator ? 'Firestore emulator (localhost:8080)' : 'live Firestore'}`);

  if (demoMode) { await setupDemo(); return; }

  if (seedLeaderboardUid) {
    const entries = LEADERBOARD.thisMonth.entries.map((e) =>
      e.rank === 5 ? { ...e, uid: seedLeaderboardUid } : e
    );
    await db.collection('leaderboard').doc('thisMonth').set({ entries });
    console.log(`\n  ✓  leaderboard/thisMonth written (your UID at rank 5)\n`);
    return;
  }

  if (addDriverUid)      { await registerUser(addDriverUid, 'driver', 'Dev Driver'); return; }
  if (addDonorUid)       { await registerUser(addDonorUid, 'donor', 'Dev Donor');   return; }
  if (addBeneficiaryUid) {
    await registerUser(addBeneficiaryUid, 'beneficiary', 'Demo Shelter');
    await db.collection('beneficiaries').doc(addBeneficiaryUid).set({
      id: addBeneficiaryUid, name: 'Demo Shelter',
      address: '88 Ratchadaphisek Rd, Khlong Toei, Bangkok 10110',
      lat: 13.7246, lng: 100.5235, intakeStatus: 'accepting',
      orgType: 'Shelter', contactEmail: 'shelter@demo.local',
      missionStatement: 'Demo beneficiary organization.',
    }, { merge: true });
    console.log(`  ✓  beneficiaries/${addBeneficiaryUid} created`);
    return;
  }

  if (cleanFirst) {
    console.log('\nMode    : clean + seed\n\nClearing existing data...');
    await clearCollection('users');
    await clearCollection('batches');
    await clearCollection('beneficiaries');
    await clearCollection('impactMetrics');
<<<<<<< HEAD
    await clearCollection('driverLocations');
=======
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
    await clearCollection('leaderboard');
    console.log();
  } else {
    console.log('\nMode    : seed (merge into existing)\n');
  }

  // Stamp updatedAt on driver locations at write time so the value is current.
  const stampedDriverLocations = DRIVER_LOCATIONS.map((d) => ({ ...d, updatedAt: iso(new Date()) }));

  console.log('Writing seed data...');
<<<<<<< HEAD
  await writeAll('beneficiaries',   BENEFICIARIES);
  await writeAll('users',           USERS,                  'uid');
  await writeAll('batches',         BATCHES);
  await writeAll('impactMetrics',   IMPACT_METRICS);
  await writeAll('driverLocations', stampedDriverLocations, 'driverId');
=======
  await writeAll('beneficiaries', BENEFICIARIES);
  await writeAll('users',         USERS, 'uid');
  await writeAll('batches',       BATCHES);
  await writeAll('impactMetrics', IMPACT_METRICS);
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
  await db.collection('leaderboard').doc('thisMonth').set(LEADERBOARD.thisMonth);
  console.log(`  ✓  leaderboard       1 document  (thisMonth, 8 entries)`);

  const open      = BATCHES.filter(b => b.status === 'open').length;
  const claimed   = BATCHES.filter(b => b.status === 'claimed').length;
  const pickedUp  = BATCHES.filter(b => b.status === 'pickedUp').length;
  const delivered = BATCHES.filter(b => b.status === 'delivered').length;
  const closed    = BATCHES.filter(b => b.status === 'closed').length;
  const cancelled = BATCHES.filter(b => b.status === 'cancelled').length;

  console.log('\nSummary:');
  console.log(`  beneficiaries  : ${BENEFICIARIES.length}  (${BENEFICIARIES.filter(b=>b.intakeStatus==='accepting').length} accepting · ${BENEFICIARIES.filter(b=>b.intakeStatus==='full').length} full)`);
  console.log(`  users          : ${USERS.length}  (8 donors · 8 drivers · 1 beneficiary user)`);
<<<<<<< HEAD
  console.log(`  batches        : ${BATCHES.length}  (${open} open · ${claimed} claimed · ${pickedUp} pickedUp · ${delivered} delivered · ${closed} closed · ${cancelled} cancelled)`);
  console.log(`  impactMetrics  : ${IMPACT_METRICS.length}`);
  console.log(`  driverLocations: ${DRIVER_LOCATIONS.length}`);
=======
  console.log(`  batches        : ${BATCHES.length}  (${open} open · ${claimed} claimed · ${pickedUp} pickedUp · ${delivered} delivered · ${cancelled} cancelled)`);
  console.log(`  impactMetrics  : ${IMPACT_METRICS.length}`);
>>>>>>> e192b2ef3a9c683f42a5a670b85030e0a54acc7c
  console.log(`  leaderboard    : 1  (thisMonth, 8 drivers)`);
  console.log('\nDone.\n');
}

main().catch((err) => {
  console.error('\n✗ Seed failed:', err.message);
  process.exit(1);
});
