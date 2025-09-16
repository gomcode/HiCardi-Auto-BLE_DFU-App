import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/services/ble_service.dart';
import '../../data/services/permission_service.dart';
import '../../core/constants/app_constants.dart';

class BleProvider extends ChangeNotifier {
  final BleService _bleService = BleService();

  List<BluetoothDevice> _allDevices = [];
  List<BluetoothDevice> _selectedDevices = [];
  bool _isScanning = false;
  String _modelFilter = AppConstants.allFilter;
  String _serialRangeStart = '';
  String _serialRangeEnd = '';

  List<BluetoothDevice> get devices => _getFilteredDevices();
  List<BluetoothDevice> get selectedDevices => _selectedDevices;
  bool get isScanning => _isScanning;
  String get modelFilter => _modelFilter;
  String get serialRangeStart => _serialRangeStart;
  String get serialRangeEnd => _serialRangeEnd;

  BleProvider() {
    _initializePermissions();
    _bleService.devicesStream.listen((devices) {
      _allDevices = devices;
      notifyListeners();
    });
  }

  Future<void> _initializePermissions() async {
    await PermissionService.requestAllPermissions();
  }

  Future<void> startScan() async {
    _isScanning = true;
    _allDevices.clear();
    notifyListeners();

    try {
      await _bleService.startScan();
    } catch (e) {
      debugPrint('스캔 오류: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  List<BluetoothDevice> _getFilteredDevices() {
    return _bleService.filterDevices(
      _allDevices,
      _modelFilter,
      _serialRangeStart.isEmpty ? null : _serialRangeStart,
      _serialRangeEnd.isEmpty ? null : _serialRangeEnd,
    );
  }

  void toggleDeviceSelection(BluetoothDevice device) {
    if (_selectedDevices.contains(device)) {
      _selectedDevices.remove(device);
    } else {
      _selectedDevices.add(device);
    }
    notifyListeners();
  }

  void selectAllFilteredDevices() {
    _selectedDevices.clear();
    _selectedDevices.addAll(_getFilteredDevices());
    notifyListeners();
  }

  void clearDeviceSelection() {
    _selectedDevices.clear();
    notifyListeners();
  }

  void setModelFilter(String filter) {
    _modelFilter = filter;
    notifyListeners();
  }

  void setSerialRange(String start, String end) {
    _serialRangeStart = start;
    _serialRangeEnd = end;
    notifyListeners();
  }

  void removeFromSelection(BluetoothDevice device) {
    _selectedDevices.removeWhere(
      (selectedDevice) => selectedDevice.remoteId.str == device.remoteId.str
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}