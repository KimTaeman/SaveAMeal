import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
export const onBatchClaimed = onDocumentUpdated('batches/{batchId}', async () => {});
