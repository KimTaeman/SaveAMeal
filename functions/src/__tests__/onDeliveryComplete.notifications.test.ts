import { writeBeneficiaryNotification } from '../onDeliveryComplete';

function makeDb(): { db: FirebaseFirestore.Firestore; addMock: jest.Mock } {
  const addMock = jest.fn().mockResolvedValue({});
  const db = {
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        collection: jest.fn(() => ({ add: addMock })),
      })),
    })),
  } as unknown as FirebaseFirestore.Firestore;
  return { db, addMock };
}

describe('writeBeneficiaryNotification', () => {
  it('writes a delivery_arrived notification to the beneficiary', async () => {
    const { db, addMock } = makeDb();
    await writeBeneficiaryNotification(db, {
      beneficiaryId: 'ben1',
      batchId: 'b1',
    });

    expect(addMock).toHaveBeenCalledTimes(1);
    const call = addMock.mock.calls[0][0];
    expect(call.type).toBe('delivery_arrived');
    expect(call.isRead).toBe(false);
    expect(call.actionBatchId).toBe('b1');
  });

  it('does nothing when beneficiaryId is undefined', async () => {
    const { db, addMock } = makeDb();
    await writeBeneficiaryNotification(db, {
      beneficiaryId: undefined,
      batchId: 'b1',
    });
    expect(addMock).not.toHaveBeenCalled();
  });
});
