/// A Modbus segéd regiszterdefiníciói: műszerenként elmentett, elnevezett
/// regiszterek és bitek, amelyeket kézzel lehet olvasni és írni (pl. baud
/// rate, paritás, Modbus ID, státuszok).
library;

/// A Modbus adattábla, amelyben az elem található.
enum ModbusRegisterKind {
  holding('holding', 'Holding register'),
  input('input', 'Input register'),
  coil('coil', 'Coil'),
  discrete('discrete', 'Discrete input');

  const ModbusRegisterKind(this.dbValue, this.label);

  final String dbValue;

  /// Nemzetközi Modbus-szakszó, ezért nincs fordítva.
  final String label;

  bool get isBit => this == coil || this == discrete;

  /// Csak a holding regiszter és a coil írható.
  bool get isWritable => this == holding || this == coil;

  static ModbusRegisterKind fromDb(Object? value) {
    for (final k in values) {
      if (k.dbValue == value) return k;
    }
    return holding;
  }
}

/// A regiszter(pár) értelmezése.
enum ModbusDataType {
  uint16('uint16', 0, 65535),
  int16('int16', -32768, 32767),
  uint32('uint32', 0, 4294967295),
  int32('int32', -2147483648, 2147483647),
  float32('float32', 0, 0);

  const ModbusDataType(this.dbValue, this.min, this.max);

  final String dbValue;
  final int min;
  final int max;

  bool get isFloat => this == float32;

  /// Két egymást követő regisztert foglal-e (32 bit).
  bool get is32Bit => this == uint32 || this == int32 || this == float32;

  static ModbusDataType fromDb(Object? value) {
    for (final t in values) {
      if (t.dbValue == value) return t;
    }
    return uint16;
  }
}

/// 32 bites értékek bájt-/szósorrendje; a `modbus_client` jelöléseivel.
const kModbusByteOrders = <String>['ABCD', 'CDAB', 'BADC', 'DCBA'];

/// Egy elnevezett regiszter vagy bit.
class ModbusRegisterDef {
  const ModbusRegisterDef({
    required this.id,
    required this.name,
    required this.kind,
    required this.address,
    this.dataType = ModbusDataType.uint16,
    this.byteOrder = 'ABCD',
    this.scale = 1,
    this.unit = '',
    this.note = '',
  });

  /// Listán belüli egyedi azonosító (a kiolvasott értékek kulcsa).
  final String id;
  final String name;
  final ModbusRegisterKind kind;

  /// 0-tól számozott protokollcím (0..65535).
  final int address;
  final ModbusDataType dataType;
  final String byteOrder;

  /// Kijelzett érték = nyers érték × szorzó.
  final double scale;
  final String unit;
  final String note;

  bool get isBit => kind.isBit;
  bool get isWritable => kind.isWritable;

  /// A kijelzett értékből a műszernek küldendő nyers érték: egész típusnál
  /// `int`, float32-nél `double`. Null, ha a típus tartományán kívül esik.
  num? rawFromDisplay(double display) {
    final raw = scale == 0 ? display : display / scale;
    if (!raw.isFinite) return null;
    if (dataType.isFloat) return raw;
    final rounded = raw.round();
    if (rounded < dataType.min || rounded > dataType.max) return null;
    return rounded;
  }

  /// A nyers értékből a kijelzett érték.
  double displayFromRaw(num raw) => raw * scale;

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.dbValue,
        'address': address,
        'data_type': dataType.dbValue,
        'byte_order': byteOrder,
        'scale': scale,
        'unit': unit,
        'note': note,
      };

  static ModbusRegisterDef? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final address = raw['address'];
    if (id is! String || name is! String || address is! int) return null;
    final order = raw['byte_order'];
    final scale = raw['scale'];
    final unit = raw['unit'];
    final note = raw['note'];
    return ModbusRegisterDef(
      id: id,
      name: name,
      kind: ModbusRegisterKind.fromDb(raw['kind']),
      address: address,
      dataType: ModbusDataType.fromDb(raw['data_type']),
      byteOrder: kModbusByteOrders.contains(order) ? order as String : 'ABCD',
      scale: scale is num && scale != 0 ? scale.toDouble() : 1,
      unit: unit is String ? unit : '',
      note: note is String ? note : '',
    );
  }

  /// Definíciók listája JSON-ból; a hibás elemeket kihagyja.
  static List<ModbusRegisterDef> listFromJson(Object? raw) {
    if (raw is! List) return const [];
    final result = <ModbusRegisterDef>[];
    for (final e in raw) {
      final d = fromJson(e);
      if (d != null) result.add(d);
    }
    return result;
  }
}
