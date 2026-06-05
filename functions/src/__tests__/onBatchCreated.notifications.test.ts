import { writeNotificationsForDrivers } from '../onBatchCreated';

// Build a minimal Firestore mock
function makeDb(driverIds: string[]): FirebaseFirestore.Firestore {
  const addMock = jest.fn().mockResolvedValue({});
  const itemsCol = { add: addMock };
  const usersCol = {
    where: jest.fn().mockReturnThis(),
    get: jest.fn().mockResolvedValue({
      empty: driverIds.length === 0,
      docs: driverIds.map((id) => ({ id })),
    }),
  };
  const db = {
    collection: jest.fn((name: string) => {
      if (name === 'users') return usersCol;
      return { doc: jest.fn(() => ({ collection: jest.fn(() => itemsCol) })) };
    }),
    // FieldValue needed for serverTimestamp
  } as unknown as FirebaseFirestore.Firestore;
  (db as any).__addMock = addMock;
  return db;
}

describe('writeNotificationsForDrivers', () => {
  it('writes a new_batch notification for each driver', async () => {
    const db = makeDb(['driver1', 'driver2']);
    await writeNotificationsForDrivers(db, {
      batchId: 'b1',
      donorName: 'Supermart',
      totalKg: 10,
      category: 'bread',
    });

    const addMock = (db as any).__addMock as jest.Mock;
    expect(addMock).toHaveBeenCalledTimes(2);
    const firstCall = addMock.mock.calls[0][0];
    expect(firstCall.type).toBe('new_batch');
    expect(firstCall.title).toBe('Pickup Alert');
    expect(firstCall.body).toContain('Supermart');
    expect(firstCall.body).toContain('bread');
    expect(firstCall.isRead).toBe(false);
    expect(firstCall.actionBatchId).toBe('b1');
  });

  it('does nothing when no drivers exist', async () => {
    const db = makeDb([]);
    await writeNotificationsForDrivers(db, {
      batchId: 'b1',
      donorName: 'Supermart',
      totalKg: 10,
      category: 'bread',
    });

    const addMock = (db as any).__addMock as jest.Mock;
    expect(addMock).not.toHaveBeenCalled();
  });
});
