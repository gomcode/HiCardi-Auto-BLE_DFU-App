import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class DfuHistoryItem {
  final String deviceId;
  final String deviceName;
  final String zipFileName;
  final bool isSuccess;
  final DateTime timestamp;
  final String? errorMessage;

  DfuHistoryItem({
    required this.deviceId,
    required this.deviceName,
    required this.zipFileName,
    required this.isSuccess,
    required this.timestamp,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'zipFileName': zipFileName,
    'isSuccess': isSuccess,
    'timestamp': timestamp.toIso8601String(),
    'errorMessage': errorMessage,
  };

  factory DfuHistoryItem.fromJson(Map<String, dynamic> json) => DfuHistoryItem(
    deviceId: json['deviceId'],
    deviceName: json['deviceName'],
    zipFileName: json['zipFileName'],
    isSuccess: json['isSuccess'],
    timestamp: DateTime.parse(json['timestamp']),
    errorMessage: json['errorMessage'],
  );
}

class DfuProvider extends ChangeNotifier {
  final List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  File? _selectedFirmwareFile;
  bool _isScanning = false;
  bool _isDfuInProgress = false;
  double _dfuProgress = 0.0;
  String _dfuStatus = '';
  String? _savedFirmwarePath;
  final List<DfuHistoryItem> _dfuHistory = [];

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  File? get selectedFirmwareFile => _selectedFirmwareFile;
  bool get isScanning => _isScanning;
  bool get isDfuInProgress => _isDfuInProgress;
  double get dfuProgress => _dfuProgress;
  String get dfuStatus => _dfuStatus;
  String? get savedFirmwarePath => _savedFirmwarePath;
  List<DfuHistoryItem> get dfuHistory => _dfuHistory;

  DfuProvider() {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _savedFirmwarePath = prefs.getString('firmware_path');
    if (_savedFirmwarePath != null) {
      _selectedFirmwareFile = File(_savedFirmwarePath!);
    }
    
    // DFU 히스토리 로드
    final historyJson = prefs.getString('dfu_history');
    if (historyJson != null) {
      final List<dynamic> historyList = jsonDecode(historyJson);
      _dfuHistory.clear();
      _dfuHistory.addAll(historyList.map((item) => DfuHistoryItem.fromJson(item)));
    }
    
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedFirmwareFile != null) {
      await prefs.setString('firmware_path', _selectedFirmwareFile!.path);
    }
  }

  Future<void> _saveDfuHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_dfuHistory.map((item) => item.toJson()).toList());
    await prefs.setString('dfu_history', historyJson);
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
          // HiCardi- 접두사가 있는 기기만 필터링
          if (result.device.platformName.isNotEmpty && 
              result.device.platformName.startsWith('HiCardi-')) {
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
          
          // 성공한 DFU를 히스토리에 추가
          _addToHistory(
            _selectedDevice!,
            _selectedFirmwareFile!.path.split('/').last,
            true,
            null,
          );
          
          notifyListeners();
        },
        onError: (deviceAddress, error, errorType, message) {
          _isDfuInProgress = false;
          _dfuStatus = 'DFU 오류: $message';
          
          // 실패한 DFU를 히스토리에 추가
          _addToHistory(
            _selectedDevice!,
            _selectedFirmwareFile!.path.split('/').last,
            false,
            message,
          );
          
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

  void _addToHistory(BluetoothDevice device, String zipFileName, bool isSuccess, String? errorMessage) {
    final historyItem = DfuHistoryItem(
      deviceId: device.remoteId.str,
      deviceName: device.platformName,
      zipFileName: zipFileName,
      isSuccess: isSuccess,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
    );
    
    // 같은 기기의 이전 기록이 있으면 제거 (최신 상태만 유지)
    _dfuHistory.removeWhere((item) => item.deviceId == device.remoteId.str);
    _dfuHistory.insert(0, historyItem); // 최신 항목을 맨 앞에 추가
    
    _saveDfuHistory();
  }

  Future<void> retryDfu(DfuHistoryItem historyItem) async {
    // 히스토리 아이템의 정보로 재시도
    final device = _devices.firstWhere(
      (d) => d.remoteId.str == historyItem.deviceId,
      orElse: () => throw Exception('기기를 찾을 수 없습니다. 다시 스캔해주세요.'),
    );
    
    // 원래 zip 파일 경로 복원
    final originalZipPath = _savedFirmwarePath;
    if (originalZipPath != null && originalZipPath.endsWith(historyItem.zipFileName)) {
      _selectedDevice = device;
      _selectedFirmwareFile = File(originalZipPath);
      notifyListeners();
      await startDfu();
    } else {
      throw Exception('원본 ZIP 파일을 찾을 수 없습니다.');
    }
  }

  void clearHistory() {
    _dfuHistory.clear();
    _saveDfuHistory();
    notifyListeners();
  }
}