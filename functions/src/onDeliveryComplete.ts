import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { computeByCategory, computeTotals } from './computations';

export const onDeliveryComplete = onDocumentUpdated(
  'batches/{batchId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Guard: only fire on the * → delivered transition.
    if (before['status'] === 'delivered' || after['status'] !== 'delivered') return;

    const batchId = event.params.batchId;
    const beneficiaryId = after['beneficiaryId'] as string | undefined;
    const donorId = after['donorId'] as string | undefined;

    // Reject IDs that contain path separators — a slash would silently write
    // to an unintended collection path in Firestore.
    const isValidId = (id: string) => id.length > 0 && !id.includes('/');
    const items = (after['items'] as Array<{ weightKg: number; category?: string }>) ?? [];
    const { totalKg, totalMeals, totalCo2e } = computeTotals(items);

    const db = admin.firestore();
    const ops: Promise<unknown>[] = [];

    // Notify beneficiary to confirm receipt.
    if (beneficiaryId && isValidId(beneficiaryId)) {
      const benSnap = await db.collection('users').doc(beneficiaryId).get();
      const benToken = benSnap.data()?.['fcmToken'] as string | undefined;
      if (benToken) {
        ops.push(
          admin.messaging()
            .send({
              token: benToken,
              notification: {
                title: 'Food has arrived',
                body: 'Tap to confirm receipt',
              },
              data: { type: 'delivery_arrived', batchId },
            })
            .catch((e) => logger.warn(`onDeliveryComplete: FCM failed — ${e}`)),
        );
      } else {
        logger.warn(
          `onDeliveryComplete: beneficiary ${beneficiaryId} has no fcmToken`,
        );
      }

      // Single set({merge:true}) with dot-notation keys for byCategory fields.
      // This creates the document on first delivery and increments atomically on
      // subsequent ones — no separate update() needed, no NOT_FOUND race.
      const categoryBreakdown = computeByCategory(items);
      const beneficiaryPayload: Record<string, unknown> = {
        totalKg: FieldValue.increment(totalKg),
        totalMeals: FieldValue.increment(totalMeals),
        totalCo2e: FieldValue.increment(totalCo2e),
        totalDeliveries: FieldValue.increment(1),
      };
      for (const [cat, kg] of Object.entries(categoryBreakdown)) {
        beneficiaryPayload[`byCategory.${cat}`] = FieldValue.increment(kg);
      }
      ops.push(
        db.collection('impactMetrics').doc(beneficiaryId).set(
          beneficiaryPayload,
          { merge: true },
        ),
      );
    }

    // Atomically increment impactMetrics for the donor and globally.
    const increment = {
      totalKg: FieldValue.increment(totalKg),
      totalMeals: FieldValue.increment(totalMeals),
      totalCo2e: FieldValue.increment(totalCo2e),
    };

    if (donorId && isValidId(donorId)) {
      ops.push(
        db.collection('impactMetrics').doc(donorId).set(increment, { merge: true }),
      );
    }
    ops.push(
      db.collection('impactMetrics').doc('global').set(increment, { merge: true }),
    );

    await Promise.all(ops);
    logger.info(
      `onDeliveryComplete: batch ${batchId} — ` +
      `${totalKg} kg, ${totalMeals} meals, ${totalCo2e} kg CO₂e`,
    );
  },
);
