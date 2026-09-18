import 'package:flutter/widgets.dart';

import '../state/card_store.dart';
import 'app_snackbar.dart';

/// The store's snackbar, for any page's [Stack]. Every full page carries one
/// so "Geri al" is reachable wherever the record was made; only the top page
/// is on stage, so it never shows twice.
class StoreSnackLayer extends StatelessWidget {
  const StoreSnackLayer({super.key, required this.store, required this.bottom});

  final CardStore store;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final snack = store.snack;
        if (snack == null) return const SizedBox.shrink();
        return AppSnackbar(
          key: ValueKey(snack.message),
          message: snack.message,
          undoable: snack.undoable,
          onUndo: store.undo,
          bottom: bottom,
          reduceMotion: MediaQuery.of(context).disableAnimations,
        );
      },
    );
  }
}
