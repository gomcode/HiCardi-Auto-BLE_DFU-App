import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/serial_validator.dart';

class BleService {
  Timer? _scanUpdateTimer;
  List<ScanResult> _latestScanResults = [];
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();

  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;

  Future<void> startScan() async {
    try {
      _latestScanResults.clear();

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: AppConstants.scanTimeoutSeconds)
      );

      FlutterBluePlus.scanResults.listen((results) {
        _latestScanResults = results;
      });

      _scanUpdateTimer?.cancel();
      _scanUpdateTimer = Timer.periodic(
        Duration(milliseconds: AppConstants.scanUpdateIntervalMs),
        (timer) => _updateScanResults()
      );

      await Future.delayed(Duration(seconds: AppConstants.scanTimeoutSeconds));
      _scanUpdateTimer?.cancel();
      _updateScanResults();

    } catch (e) {
      debugPrint('스캔 오류: $e');
      rethrow;
    }
  }

  void _updateScanResults() {
    final List<BluetoothDevice> devices = [];

    for (ScanResult result in _latestScanResults) {
      if (result.device.platformName.isNotEmpty &&
          result.device.platformName.startsWith(AppConstants.hiCardiPrefix)) {
        devices.add(result.device);
      }
    }

    _devicesController.add(devices);
  }

  List<BluetoothDevice> filterDevices(
    List<BluetoothDevice> devices,
    String modelFilter,
    String? serialRangeStart,
    String? serialRangeEnd,
  ) {
    return devices.where((device) {
      final String deviceName = device.platformName;

      if (!_matchesModelFilter(deviceName, modelFilter)) {
        return false;
      }

      return SerialValidator.isSerialInRange(
        deviceName,
        serialRangeStart,
        serialRangeEnd
      );
    }).toList();
  }

  bool _matchesModelFilter(String deviceName, String modelFilter) {
    if (modelFilter == AppConstants.allFilter) {
      return deviceName.startsWith(AppConstants.hiCardiPrefix);
    } else if (modelFilter == AppConstants.hiCardiPrefix) {
      return RegExp(r'^HiCardi-[0-9]').hasMatch(deviceName);
    } else {
      return deviceName.startsWith(modelFilter);
    }
  }

  void dispose() {
    _scanUpdateTimer?.cancel();
    _devicesController.close();
  }
}