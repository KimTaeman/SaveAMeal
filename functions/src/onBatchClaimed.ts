import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

export async function writeDonorNotification(
  db: FirebaseFirestore.Firestore,
  params: { donorId: string | undefined; batchId: string },
): Promise<void> {
  const { donorId, batchId } = params;
  if (!donorId) return;
  await db
    .collection('notifications')
    .doc(donorId)
    .collection('items')
    .add({
      type: 'driver_assigned',
      title: 'Driver is on the way',
      body: 'Your batch is being picked up',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      actionBatchId: batchId,
    });
}

export const onBatchClaimed = onDocumentUpdated(
  { document: 'batches/{batchId}', region: 'asia-southeast1' },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    if (before['status'] === 'claimed' || after['status'] !== 'claimed') return;

    const batchId = event.params.batchId;
    const donorId = after['donorId'] as string | undefined;
    const beneficiaryId = after['beneficiaryId'] as string | undefined;
    const donorName = (after['donorName'] as string | undefined) ?? 'A donor';
    const items = (after['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg } = computeTotals(items);

    const db = admin.firestore();

    const [donorSnap, benSnap] = await Promise.all([
      donorId ? db.collection('users').doc(donorId).get() : Promise.resolve(null),
      beneficiaryId ? db.collection('users').doc(beneficiaryId).get() : Promise.resolve(null),
    ]);

    const sends: Promise<void>[] = [];

    const donorToken = donorSnap?.data()?.['fcmToken'] as string | undefined;
    if (donorToken) {
      sends.push(
        admin
          .messaging()
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
    } else if (donorId) {
      logger.warn(`onBatchClaimed: donor ${donorId} has no fcmToken`);
    }

    const benToken = benSnap?.data()?.['fcmToken'] as string | undefined;
    if (benToken) {
      sends.push(
        admin
          .messaging()
          .send({
            token: benToken,
            notification: {
              title: 'Delivery incoming',
              body: `${formatKg(totalKg)} kg from ${donorName}`,
            },
            data: { type: 'incoming_delivery', batchId },
          })
          .then(() => undefined)
          .catch((e) =>
            logger.warn(`onBatchClaimed: beneficiary FCM failed — ${e}`),
          ),
      );
    } else if (beneficiaryId) {
      logger.warn(`onBatchClaimed: beneficiary ${beneficiaryId} has no fcmToken`);
    }

    await Promise.all(sends);

    await writeDonorNotification(db, { donorId, batchId }).catch((e) =>
      logger.warn(`onBatchClaimed: donor notification write failed — ${e}`),
    );

    logger.info(
      `onBatchClaimed: notifications dispatched for batch ${batchId}`,
    );
  },
);
