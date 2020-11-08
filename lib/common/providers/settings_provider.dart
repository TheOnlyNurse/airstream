import 'dart:async';

/// External Packages
import 'package:connectivity/connectivity.dart';
import 'package:hive/hive.dart';

/// Internal Links
import '../repository/communication.dart';

class SettingsProvider {
  final _hiveBox = Hive.box('settings');

  /// Listenable stream of changed settings
  Stream<SettingType> get onSettingsChange => _settingChanged.stream;

  /// Broadcast setting type on change
  final _settingChanged = StreamController<SettingType>.broadcast();

  /// Query a setting in box or return default
  T query<T>(SettingType type) {
    final response = _hiveBox.get(type.index) as T;
    return response ?? _defaults[type] as T;
  }

  /// Validate a given value before setting it as the new value
  void change<T>(SettingType type, T newValue) {
    assert(newValue.runtimeType == query(type).runtimeType);
    if (_range.containsKey(type)) {
      final number = newValue as int;
      assert(number > _range[type][0] - 1);
      assert(number < _range[type][1] + 1);
    }

    _hiveBox.put(type.index, newValue);
    _settingChanged.add(type);
  }

  List<int> range(SettingType type) => _range[type];

  /// Permitted range for defaults.
  final _range = <SettingType, List<int>>{
    SettingType.prefetch: [0, 3],
    SettingType.imageCache: [20, 200],
    SettingType.musicCache: [100, 3000],
    SettingType.mobileBitrate: [32, 320],
    SettingType.wifiBitrate: [32, 320],
  };

  /// Default values for setting options.
  final _defaults = <SettingType, dynamic>{
    SettingType.isOffline: false,
    SettingType.prefetch: 1,
    SettingType.imageCache: 80,
    SettingType.musicCache: 1000,
    SettingType.mobileBitrate: 256,
    SettingType.wifiBitrate: 320,
    SettingType.autoOffline: false,
  };

  /// Change to offline mode when in aeroplane or similar mode
  void _onConnectivityChange(ConnectivityResult result) {
    void onWifi() {
      final mobileOffline = query<bool>(SettingType.autoOffline);
      if (mobileOffline) change(SettingType.isOffline, false);
    }

    void onMobile() {
      final mobileOffline = query<bool>(SettingType.autoOffline);
      if (mobileOffline) change(SettingType.isOffline, true);
    }

    void onOffline() {
      final isOffline = query<bool>(SettingType.isOffline);
      if (!isOffline) change(SettingType.isOffline, true);
    }

    switch (result) {
      case ConnectivityResult.wifi:
        onWifi();
        break;
      case ConnectivityResult.mobile:
        onMobile();
        break;
      case ConnectivityResult.none:
        onOffline();
        break;
    }
  }

  /// Singleton boilerplate code
  factory SettingsProvider() => _instance;
  static final SettingsProvider _instance = SettingsProvider._internal();

  SettingsProvider._internal() {
    Connectivity().onConnectivityChanged.listen(_onConnectivityChange);
  }


}
