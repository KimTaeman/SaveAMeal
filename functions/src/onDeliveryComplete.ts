import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
export const onDeliveryComplete = onDocumentUpdated('batches/{batchId}', async () => {});
