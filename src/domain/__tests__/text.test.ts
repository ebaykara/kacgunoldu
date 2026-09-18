import { capitalizeTr } from '../text';

describe('capitalizeTr', () => {
  it('capitalizes plain ASCII letters', () => {
    expect(capitalizeTr('çamaşır yıkadım')).toBe('Çamaşır yıkadım');
  });

  it('turns a leading "i" into dotted "İ", not ASCII "I"', () => {
    expect(capitalizeTr('ilaç aldım')).toBe('İlaç aldım');
  });

  it('leaves a leading dotless "ı" as-is other than casing', () => {
    expect(capitalizeTr('ışık yaktım')).toBe('Işık yaktım');
  });

  it('is a no-op on empty input', () => {
    expect(capitalizeTr('')).toBe('');
  });
});
