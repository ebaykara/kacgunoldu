import AsyncStorage from '@react-native-async-storage/async-storage';
import { loadManualOrder, saveManualOrder } from '../repository';

describe('manual order persistence', () => {
  afterEach(async () => {
    await AsyncStorage.clear();
  });

  it('round-trips a saved arrangement', async () => {
    await saveManualOrder(['b', 'c', 'a']);
    expect(await loadManualOrder()).toEqual(['b', 'c', 'a']);
  });

  it('is null before anything has ever been dragged', async () => {
    expect(await loadManualOrder()).toBeNull();
  });

  it('recovers from corrupted storage rather than throwing', async () => {
    await AsyncStorage.setItem('nezaman.order.v1', 'not json{{{');
    expect(await loadManualOrder()).toBeNull();
  });

  it('rejects a malformed shape instead of returning it verbatim', async () => {
    await AsyncStorage.setItem('nezaman.order.v1', JSON.stringify([1, 2, 3]));
    expect(await loadManualOrder()).toBeNull();
  });
});
