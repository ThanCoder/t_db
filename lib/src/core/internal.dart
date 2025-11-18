import 'dart:io';

class TMap {
  static String getString(
    Map<String, dynamic> map,
    List<String> keys, {
    String defaultValue = '',
  }) {
    return get<String>(map, keys, defaultValue: defaultValue);
  }

  static double getDouble(
    Map<String, dynamic> map,
    List<String> keys, {
    double defaultValue = 0.0,
  }) {
    return get<double>(map, keys, defaultValue: defaultValue);
  }

  static int getInt(
    Map<String, dynamic> map,
    List<String> keys, {
    int defaultValue = 0,
  }) {
    return get<int>(map, keys, defaultValue: defaultValue);
  }

  static bool getBool(
    Map<String, dynamic> map,
    List<String> keys, {
    bool defaultValue = false,
  }) {
    return get<bool>(map, keys, defaultValue: defaultValue);
  }

  static T get<T>(
    Map<String, dynamic> map,
    List<String> keys, {
    required T defaultValue,
  }) {
    dynamic current = map;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      }
    }
    // string ကိုယူမှာ
    if (T == String && current is int) {
      current = current.toString();
    }
    if (T == String && current is double) {
      current = current.toString();
    }
    // int ကိုယူမှာ
    if (T == int && current is String) {
      if (int.tryParse(current) != null) {
        current = int.parse(current);
      }
    }
    // double ကိုယူမှာ
    if (T == double && current is String) {
      if (double.tryParse(current) != null) {
        current = double.parse(current);
      }
    }
    // custom type အတွက်မရေးထားဘူး

    return current is T ? current : defaultValue;
  }
}

extension TMapExtension on Map<String, dynamic> {
  String getString(List<String> keys, {String def = ''}) {
    return TMap.getString(this, keys, defaultValue: def);
  }

  int getInt(List<String> keys, {int def = 0}) {
    return TMap.getInt(this, keys, defaultValue: def);
  }

  double getDouble(List<String> keys, {double def = 0.0}) {
    return TMap.getDouble(this, keys, defaultValue: def);
  }

  bool getBool(List<String> keys, {bool def = false}) {
    return TMap.getBool(this, keys, defaultValue: def);
  }

  T get<T>(List<String> keys, {required T def}) {
    return TMap.get<T>(this, keys, defaultValue: def);
  }
}

extension DoubleExtension on double {
  String toFileSizeLabel({int asFixed = 2}) {
    String res = '';
    int pow = 1024;
    final labels = ['byte', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = this;
    while (size > pow) {
      size /= pow;
      i++;
    }

    res = '${size.toStringAsFixed(asFixed)} ${labels[i]}';

    return res;
  }

  String getAutoSpeedLabel() {
    if (this == 0) {
      return '';
    }
    if (this >= 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
    } else if (this >= 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    } else if (this >= 1024) {
      return '${(this / 1024).toStringAsFixed(2)} KB/s';
    } else {
      return '${toStringAsFixed(0)} B/s';
    }
  }
}

extension IntExtension on int {
  String getSizeLabel({int asFixed = 2}) {
    return toDouble().toFileSizeLabel(asFixed: asFixed);
  }

  String toFileSizeLabel({int asFixed = 2}) {
    return toDouble().toFileSizeLabel(asFixed: asFixed);
  }
}

extension StringExtension on String {
  String toCaptalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1, length)}';
  }

  String getName({bool withExt = true}) {
    final name = split(Platform.pathSeparator).last;
    if (!withExt) {
      return name.split('.').first;
    }
    return name;
  }

  String get getExt {
    return split(Platform.pathSeparator).last;
  }

  String pathJoin(String path, String name) {
    return '$path${Platform.pathSeparator}$name';
  }
}
