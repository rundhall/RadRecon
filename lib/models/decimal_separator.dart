/// A jegyzőkönyvben használt tizedesjel (a Beállításokban választható).
/// `auto`: az alkalmazás nyelve szerint (angol: pont, többi nyelv: vessző).
enum DecimalSeparatorMode {
  auto('auto'),
  comma('comma'),
  dot('dot');

  const DecimalSeparatorMode(this.storageValue);

  final String storageValue;

  static const defaultMode = DecimalSeparatorMode.auto;

  static DecimalSeparatorMode fromStorage(String? value) =>
      DecimalSeparatorMode.values.firstWhere(
        (m) => m.storageValue == value,
        orElse: () => defaultMode,
      );
}

/// A ténylegesen használt tizedesjel: a beállítás szerint, `auto` esetén
/// az [autoSeparator] (az app nyelvének `protoDecimalSep` értéke).
String decimalSeparatorFor(DecimalSeparatorMode mode, String autoSeparator) =>
    switch (mode) {
      DecimalSeparatorMode.comma => ',',
      DecimalSeparatorMode.dot => '.',
      DecimalSeparatorMode.auto => autoSeparator,
    };
