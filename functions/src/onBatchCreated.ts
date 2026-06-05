import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

function primaryCategory(items: Array<{ category?: string }>): string {
  const counts: Record<string, number> = {};
  for (const item of items) {
    const cat = item.category ?? 'food';
    counts[cat] = (counts[cat] ?? 0) + 1;
  }
  return Object.entries(counts).sort((a, b) => b[1] - a[1])[0]?.[0] ?? 'food';
}

function buildDriverBody(donorName: string, totalKg: number, category: string): string {
  return `New pickup available nearby! ${donorName} has ${formatKg(totalKg)}kg of surplus ${category}.`;
}

export async function writeNotificationsForDrivers(
  db: FirebaseFirestore.Firestore,
  params: { batchId: string; donorName: string; totalKg: number; category: string },
): Promise<void> {
  const { batchId, donorName, totalKg, category } = params;
  const driversSnap = await db
    .collection('users')
    .where('role', '==', 'driver')
    .get();
  if (driversSnap.empty) return;

  const body = buildDriverBody(donorName, totalKg, category);
  await Promise.all(
    driversSnap.docs.map((doc) =>
      db.collection('notifications').doc(doc.id).collection('items').add({
        type: 'new_batch',
        title: 'Pickup Alert',
        body,
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
    const items = (batch['items'] as Array<{ weightKg: number; category?: string }>) ?? [];
    const { totalKg } = computeTotals(items);
    const category = primaryCategory(items);
    const body = buildDriverBody(donorName, totalKg, category);

    await admin
      .messaging()
      .send({
        topic: 'new_batch_available',
        notification: {
          title: 'Pickup Alert',
          body,
        },
        data: { type: 'new_batch', batchId },
      })
      .catch((e) => logger.warn(`onBatchCreated: topic FCM failed — ${e}`));

    await writeNotificationsForDrivers(admin.firestore(), {
      batchId,
      donorName,
      totalKg,
      category,
    }).catch((e) =>
      logger.warn(`onBatchCreated: notification write failed — ${e}`),
    );

    logger.info(
      `onBatchCreated: FCM + notifications sent for batch ${batchId}`,
    );
  },
);
