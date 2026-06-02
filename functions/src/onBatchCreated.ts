import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeTotals, formatKg } from './computations';

export const onBatchCreated = onDocumentCreated(
  'batches/{batchId}',
  async (event) => {
    const batch = event.data?.data();
    if (!batch) return;

    const batchId = event.params.batchId;
    const donorName = (batch['donorName'] as string | undefined) ?? 'A donor';
    const items = (batch['items'] as Array<{ weightKg: number }>) ?? [];
    const { totalKg } = computeTotals(items);

    await admin.messaging().send({
      topic: 'new_batch_available',
      notification: {
        title: 'New pickup available',
        body: `${donorName} · ${formatKg(totalKg)} kg`,
      },
      data: { type: 'new_batch', batchId },
    });

    logger.info(`onBatchCreated: topic msg sent for batch ${batchId}`);
  },
);
