import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

export const onBatchClaimed = onDocumentUpdated(
  'batches/{batchId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Guard: only fire on the open → claimed transition.
    if (before['status'] === 'claimed' || after['status'] !== 'claimed') return;

    const batchId = event.params.batchId;
    const donorId = after['donorId'] as string | undefined;
    const beneficiaryId = after['beneficiaryId'] as string | undefined;
    const donorName = (after['donorName'] as string | undefined) ?? 'A donor';
    const items = (after['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg } = computeTotals(items);

    const db = admin.firestore();
    const sends: Promise<void>[] = [];

    // Notify donor.
    if (donorId) {
      const donorSnap = await db.collection('users').doc(donorId).get();
      const donorToken = donorSnap.data()?.['fcmToken'] as string | undefined;
      if (donorToken) {
        sends.push(
          admin.messaging()
            .send({
              token: donorToken,
              notification: {
                title: 'Driver is on the way',
                body: 'Your batch is being picked up',
              },
              data: { type: 'driver_assigned', batchId },
            })
            .then(() => undefined)
            .catch((e) => logger.warn(`onBatchClaimed: donor FCM failed — ${e}`)),
        );
      } else {
        logger.warn(`onBatchClaimed: donor ${donorId} has no fcmToken`);
      }
    }

    // Notify beneficiary.
    if (beneficiaryId) {
      const benSnap = await db.collection('users').doc(beneficiaryId).get();
      const benToken = benSnap.data()?.['fcmToken'] as string | undefined;
      if (benToken) {
        sends.push(
          admin.messaging()
            .send({
              token: benToken,
              notification: {
                title: 'Delivery incoming',
                body: `${formatKg(totalKg)} kg from ${donorName}`,
              },
              data: { type: 'incoming_delivery', batchId },
            })
            .then(() => undefined)
            .catch((e) => logger.warn(`onBatchClaimed: beneficiary FCM failed — ${e}`)),
        );
      } else {
        logger.warn(`onBatchClaimed: beneficiary ${beneficiaryId} has no fcmToken`);
      }
    }

    await Promise.all(sends);
    logger.info(`onBatchClaimed: notifications dispatched for batch ${batchId}`);
  },
);
