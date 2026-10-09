import 'package:flutter/widgets.dart';

/// Az egész widget-fa újraépítése. Az adatbázis lecserélése (betöltés,
/// törlés, cégváltás) után minden képernyőnek újra kell olvasnia az adatot;
/// az új kulcs eldobja az összes nyitott képernyőt és a főképernyőről indul.
class AppReset {
  static final ValueNotifier<int> generation = ValueNotifier<int>(0);
  static void reset() => generation.value++;
}

class AppResetScope extends StatelessWidget {
  const AppResetScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppReset.generation,
      builder: (context, gen, _) => KeyedSubtree(
        key: ValueKey<int>(gen),
        child: child,
      ),
    );
  }
}
