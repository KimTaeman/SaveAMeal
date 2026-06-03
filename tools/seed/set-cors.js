/**
 * SaveAMeal — Firebase Storage CORS setup
 *
 * Fixes "No Access-Control-Allow-Origin" errors when loading profile/banner
 * images in the Flutter web build.
 *
 * Usage:
 *   node set-cors.js --key serviceAccountKey.json
 */

'use strict';

const admin = require('firebase-admin');
const path  = require('path');

const keyIdx  = process.argv.indexOf('--key');
const keyPath = keyIdx >= 0 ? process.argv[keyIdx + 1] : null;

if (!keyPath) {
  console.error(
    '\nERROR: Must supply --key serviceAccountKey.json\n\n' +
    'Usage: node set-cors.js --key serviceAccountKey.json\n',
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(path.resolve(keyPath))),
  storageBucket: 'saveameal-87187.firebasestorage.app',
});

const corsConfig = [
  {
    origin: ['*'],
    method: ['GET', 'HEAD'],
    responseHeader: [
      'Content-Type',
      'Access-Control-Allow-Origin',
      'Content-Range',
      'Content-Length',
    ],
    maxAgeSeconds: 3600,
  },
];

async function main() {
  const bucket = admin.storage().bucket();
  console.log(`\nSetting CORS on bucket: ${bucket.name}`);

  // @google-cloud/storage exposes setMetadata which accepts a 'cors' field.
  await bucket.setMetadata({ cors: corsConfig });

  const [meta] = await bucket.getMetadata();
  console.log('\n✓  CORS configured:');
  console.log(JSON.stringify(meta.cors, null, 2));
  console.log('\nDone. Reload the Flutter web app to verify.\n');
}

main().catch((err) => {
  console.error('\n✗  Failed:', err.message);
  process.exit(1);
});
