import { Alert, Platform } from 'react-native';

/**
 * Ask before something irreversible.
 *
 * On iOS and Android this is the platform's own destructive alert, which is
 * what HIG and Material both call for. `react-native-web` ships `Alert.alert`
 * as a silent no-op, so the web build falls back to the browser's confirm —
 * otherwise the action would appear to do nothing there.
 */
export function confirmDestructive(options: {
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
}) {
  const { title, message, confirmLabel, cancelLabel, onConfirm } = options;

  if (Platform.OS === 'web') {
    const ok =
      typeof globalThis !== 'undefined' && typeof globalThis.confirm === 'function'
        ? globalThis.confirm(`${title}\n\n${message}`)
        : false;
    if (ok) onConfirm();
    return;
  }

  Alert.alert(
    title,
    message,
    [
      { text: cancelLabel, style: 'cancel' },
      { text: confirmLabel, style: 'destructive', onPress: onConfirm },
    ],
    { cancelable: true },
  );
}
