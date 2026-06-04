import { writeDonorNotification } from '../onBatchClaimed';

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

describe('writeDonorNotification', () => {
  it('writes a driver_assigned notification to the donor', async () => {
    const { db, addMock } = makeDb();
    await writeDonorNotification(db, { donorId: 'donor1', batchId: 'b1' });

    expect(addMock).toHaveBeenCalledTimes(1);
    const call = addMock.mock.calls[0][0];
    expect(call.type).toBe('driver_assigned');
    expect(call.isRead).toBe(false);
    expect(call.actionBatchId).toBe('b1');
  });

  it('does nothing when donorId is undefined', async () => {
    const { db, addMock } = makeDb();
    await writeDonorNotification(db, { donorId: undefined, batchId: 'b1' });
    expect(addMock).not.toHaveBeenCalled();
  });
});
