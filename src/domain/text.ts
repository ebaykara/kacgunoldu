/**
 * Capitalise the first letter using Turkish casing rules — `i` becomes `İ`
 * (dotted), not the ASCII `I`, and `ı` is left as the lowercase dotless letter
 * it already is. `String.toUpperCase()` without a locale gets this wrong.
 */
export function capitalizeTr(text: string): string {
  if (!text) return text;
  return text[0].toLocaleUpperCase('tr-TR') + text.slice(1);
}
