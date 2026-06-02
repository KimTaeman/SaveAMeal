import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

export { onBatchCreated } from './onBatchCreated';
export { onBatchClaimed } from './onBatchClaimed';
export { onDeliveryComplete } from './onDeliveryComplete';
