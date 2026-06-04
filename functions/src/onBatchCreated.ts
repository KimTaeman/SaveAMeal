import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

export async function writeNotificationsForDrivers(
  db: FirebaseFirestore.Firestore,
  params: { batchId: string; donorName: string; totalKg: number },
): Promise<void> {
  const { batchId, donorName, totalKg } = params;
  const driversSnap = await db
    .collection('users')
    .where('role', '==', 'driver')
    .get();
  if (driversSnap.empty) return;

  await Promise.all(
    driversSnap.docs.map((doc) =>
      db.collection('notifications').doc(doc.id).collection('items').add({
        type: 'new_batch',
        title: 'New pickup available',
        body: `${donorName} · ${formatKg(totalKg)} kg`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        actionBatchId: batchId,
      }),
    ),
  );
}

export const onBatchCreated = onDocumentCreated(
  { document: 'batches/{batchId}', region: 'asia-southeast1' },
  async (event) => {
    const batch = event.data?.data();
    if (!batch) return;

    const batchId = event.params.batchId;
    const donorName = (batch['donorName'] as string | undefined) ?? 'A donor';
    const items = (batch['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg } = computeTotals(items);

    await admin
      .messaging()
      .send({
        topic: 'new_batch_available',
        notification: {
          title: 'New pickup available',
          body: `${donorName} · ${formatKg(totalKg)} kg`,
        },
        data: { type: 'new_batch', batchId },
      })
      .catch((e) => logger.warn(`onBatchCreated: topic FCM failed — ${e}`));

    await writeNotificationsForDrivers(admin.firestore(), {
      batchId,
      donorName,
      totalKg,
    }).catch((e) =>
      logger.warn(`onBatchCreated: notification write failed — ${e}`),
    );

    logger.info(
      `onBatchCreated: FCM + notifications sent for batch ${batchId}`,
    );
  },
);
