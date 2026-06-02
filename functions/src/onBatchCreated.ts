import { onDocumentCreated } from 'firebase-functions/v2/firestore';
export const onBatchCreated = onDocumentCreated('batches/{batchId}', async () => {});
