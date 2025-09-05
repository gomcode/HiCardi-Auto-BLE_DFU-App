import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DfuProvider extends ChangeNotifier {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  File? _selectedFirmwareFile;
  bool _isScanning = false;
  bool _isDfuInProgress = false;
  double _dfuProgress = 0.0;
  String _dfuStatus = '';
  String? _savedFirmwarePath;

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  File? get selectedFirmwareFile => _selectedFirmwareFile;
  bool get isScanning => _isScanning;
  bool get isDfuInProgress => _isDfuInProgress;
  double get dfuProgress => _dfuProgress;
  String get dfuStatus => _dfuStatus;
  String? get savedFirmwarePath => _savedFirmwarePath;

  DfuProvider() {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _savedFirmwarePath = prefs.getString('firmware_path');
    if (_savedFirmwarePath != null) {
      _selectedFirmwareFile = File(_savedFirmwarePath!);
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedFirmwareFile != null) {
      await prefs.setString('firmware_path', _selectedFirmwareFile!.path);
    }
  }

  Future<void> startScan() async {
    _isScanning = true;
    _devices.clear();
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      FlutterBluePlus.scanResults.listen((results) {
        _devices.clear();
        for (ScanResult result in results) {
          if (result.device.platformName.isNotEmpty) {
            _devices.add(result.device);
          }
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('스캔 오류: $e');
    }

    await Future.delayed(const Duration(seconds: 10));
    _isScanning = false;
    notifyListeners();
  }

  void selectDevice(BluetoothDevice device) {
    _selectedDevice = device;
    notifyListeners();
  }

  void selectFirmwareFile(File file) {
    _selectedFirmwareFile = file;
    _saveSettings();
    notifyListeners();
  }

  Future<void> startDfu() async {
    if (_selectedDevice == null || _selectedFirmwareFile == null) {
      return;
    }

    _isDfuInProgress = true;
    _dfuProgress = 0.0;
    _dfuStatus = 'DFU 시작 중...';
    notifyListeners();

    try {
      await NordicDfu().startDfu(
        _selectedDevice!.remoteId.str,
        _selectedFirmwareFile!.path,
        onProgressChanged: (deviceAddress, percent, speed, avgSpeed, currentPart, partsTotal) {
          _dfuProgress = percent / 100.0;
          _dfuStatus = 'DFU 진행 중... $percent%';
          notifyListeners();
        },
        onDfuCompleted: (deviceAddress) {
          _isDfuInProgress = false;
          _dfuProgress = 1.0;
          _dfuStatus = 'DFU 완료!';
          notifyListeners();
        },
        onError: (deviceAddress, error, errorType, message) {
          _isDfuInProgress = false;
          _dfuStatus = 'DFU 오류: $message';
          notifyListeners();
        },
      );
    } catch (e) {
      _isDfuInProgress = false;
      _dfuStatus = 'DFU 오류: $e';
      notifyListeners();
    }
  }

  void resetDfu() {
    _isDfuInProgress = false;
    _dfuProgress = 0.0;
    _dfuStatus = '';
    notifyListeners();
  }
}