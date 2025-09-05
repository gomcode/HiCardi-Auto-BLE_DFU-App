import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

class DeviceDfuProgress {
  final String deviceId;
  final String deviceName;
  double progress;
  String status;
  bool isCompleted;
  bool isError;
  String? errorMessage;

  DeviceDfuProgress({
    required this.deviceId,
    required this.deviceName,
    this.progress = 0.0,
    this.status = '대기 중',
    this.isCompleted = false,
    this.isError = false,
    this.errorMessage,
  });
}

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
  final List<BluetoothDevice> _selectedDevices = [];
  File? _selectedFirmwareFile;
  bool _isScanning = false;
  bool _isDfuInProgress = false;
  double _dfuProgress = 0.0;
  String _dfuStatus = '';
  String? _savedFirmwarePath;
  final List<DfuHistoryItem> _dfuHistory = [];
  
  // 필터링 관련 변수들
  String _modelFilter = '전체'; // 기본값
  String _serialRangeStart = '';
  String _serialRangeEnd = '';
  
  // 다중 DFU 진행률 관련 변수들
  final Map<String, DeviceDfuProgress> _deviceProgressMap = {};
  int _currentDfuIndex = 0;
  int _totalDfuDevices = 0;

  List<BluetoothDevice> get devices => _getFilteredDevices();
  List<BluetoothDevice> get selectedDevices => _selectedDevices;
  File? get selectedFirmwareFile => _selectedFirmwareFile;
  bool get isScanning => _isScanning;
  bool get isDfuInProgress => _isDfuInProgress;
  double get dfuProgress => _dfuProgress;
  String get dfuStatus => _dfuStatus;
  String? get savedFirmwarePath => _savedFirmwarePath;
  List<DfuHistoryItem> get dfuHistory => _dfuHistory;
  String get modelFilter => _modelFilter;
  String get serialRangeStart => _serialRangeStart;
  String get serialRangeEnd => _serialRangeEnd;
  Map<String, DeviceDfuProgress> get deviceProgressMap => _deviceProgressMap;
  int get currentDfuIndex => _currentDfuIndex;
  int get totalDfuDevices => _totalDfuDevices;
  bool get isMultipleDfu => _totalDfuDevices > 1;

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

  Timer? _scanUpdateTimer;
  List<ScanResult> _latestScanResults = [];
  
  Future<void> startScan() async {
    _isScanning = true;
    _devices.clear();
    _latestScanResults.clear();
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      // 스캔 결과를 실시간으로 저장
      FlutterBluePlus.scanResults.listen((results) {
        _latestScanResults = results;
      });
      
      // UI 업데이트를 주기적으로 수행 (500ms마다)
      _scanUpdateTimer?.cancel();
      _scanUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _updateScanResults();
      });
      
    } catch (e) {
      debugPrint('스캔 오류: $e');
    }

    await Future.delayed(const Duration(seconds: 10));
    _scanUpdateTimer?.cancel();
    _isScanning = false;
    _updateScanResults(); // 마지막 업데이트
    notifyListeners();
  }
  
  void _updateScanResults() {
    final previousDeviceCount = _devices.length;
    _devices.clear();
    
    for (ScanResult result in _latestScanResults) {
      // HiCardi- 접두사가 있는 기기만 필터링
      if (result.device.platformName.isNotEmpty && 
          result.device.platformName.startsWith('HiCardi-')) {
        _devices.add(result.device);
      }
    }
    
    // 기기 수가 변경되었을 때만 UI 업데이트
    if (_devices.length != previousDeviceCount) {
      notifyListeners();
    }
  }

  List<BluetoothDevice> _getFilteredDevices() {
    List<BluetoothDevice> filtered = [];
    
    for (BluetoothDevice device in _devices) {
      String deviceName = device.platformName;
      
      // 모델 필터링
      bool modelMatch = false;
      if (_modelFilter == '전체') {
        // 모든 HiCardi- 기기 허용
        modelMatch = deviceName.startsWith('HiCardi-');
      } else if (_modelFilter == 'HiCardi-') {
        // 정확히 'HiCardi-' 다음에 숫자가 오는 경우만 (알파벳이 없는 경우)
        modelMatch = RegExp(r'^HiCardi-[0-9]').hasMatch(deviceName);
      } else {
        // 특정 모델 (A, C, D, E, M, N)
        modelMatch = deviceName.startsWith(_modelFilter);
      }
      
      if (!modelMatch) continue;
      
      // 시리얼 번호 범위 필터링
      if (_serialRangeStart.isNotEmpty || _serialRangeEnd.isNotEmpty) {
        // HiCardi-X00000 형태에서 마지막 5자리 추출
        RegExp serialRegex = RegExp(r'HiCardi-[A-Z]?(\d{5})');
        Match? match = serialRegex.firstMatch(deviceName);
        
        if (match != null) {
          String serialNumber = match.group(1)!;
          int serial = int.tryParse(serialNumber) ?? 0;
          
          if (_serialRangeStart.isNotEmpty) {
            int startSerial = int.tryParse(_serialRangeStart) ?? 0;
            if (serial < startSerial) continue;
          }
          
          if (_serialRangeEnd.isNotEmpty) {
            int endSerial = int.tryParse(_serialRangeEnd) ?? 99999;
            if (serial > endSerial) continue;
          }
        } else if (_serialRangeStart.isNotEmpty || _serialRangeEnd.isNotEmpty) {
          // 시리얼 번호 형태가 맞지 않으면 제외
          continue;
        }
      }
      
      filtered.add(device);
    }
    
    return filtered;
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

  void selectFirmwareFile(File file) {
    _selectedFirmwareFile = file;
    _saveSettings();
    notifyListeners();
  }

  Future<void> startDfu() async {
    if (_selectedDevices.isEmpty || _selectedFirmwareFile == null) {
      return;
    }

    _isDfuInProgress = true;
    _currentDfuIndex = 0;
    _totalDfuDevices = _selectedDevices.length;
    _deviceProgressMap.clear();
    
    // 선택된 기기들을 이름 오름차순으로 정렬
    final sortedDevices = _selectedDevices.toList();
    sortedDevices.sort((a, b) => a.platformName.compareTo(b.platformName));
    
    // 각 기기별 진행률 초기화
    for (final device in sortedDevices) {
      _deviceProgressMap[device.remoteId.str] = DeviceDfuProgress(
        deviceId: device.remoteId.str,
        deviceName: device.platformName,
      );
    }
    
    if (_totalDfuDevices == 1) {
      _dfuProgress = 0.0;
      _dfuStatus = 'DFU 시작 중...';
    } else {
      _dfuProgress = 0.0;
      _dfuStatus = '다중 DFU 시작 중... (총 $_totalDfuDevices개 기기)';
    }
    
    notifyListeners();
    
    // 순차적으로 각 기기에 DFU 실행 (정렬된 순서로)
    await _processDfuSequentially(sortedDevices);
  }
  
  Future<void> _processDfuSequentially(List<BluetoothDevice> sortedDevices) async {
    for (int i = 0; i < sortedDevices.length; i++) {
      _currentDfuIndex = i;
      final device = sortedDevices[i];
      final deviceProgress = _deviceProgressMap[device.remoteId.str]!;
      
      // 현재 기기 상태를 '진행 중'으로 변경
      deviceProgress.status = '진행 중';
      
      if (_totalDfuDevices > 1) {
        _dfuStatus = '기기 ${i + 1}/$_totalDfuDevices: ${device.platformName} DFU 진행 중...';
      } else {
        _dfuStatus = 'DFU 진행 중...';
      }
      
      notifyListeners();
      
      try {
        await _performSingleDfu(device, deviceProgress);
      } catch (e) {
        deviceProgress.isError = true;
        deviceProgress.status = '오류';
        deviceProgress.errorMessage = e.toString();
        
        // 실패한 DFU를 히스토리에 추가
        _addToHistory(
          device,
          _selectedFirmwareFile!.path.split('/').last,
          false,
          e.toString(),
        );
      }
      
      notifyListeners();
    }
    
    // 모든 DFU 완료
    _isDfuInProgress = false;
    final completedCount = _deviceProgressMap.values.where((p) => p.isCompleted).length;
    final errorCount = _deviceProgressMap.values.where((p) => p.isError).length;
    
    if (_totalDfuDevices > 1) {
      _dfuStatus = '다중 DFU 완료! 성공: $completedCount개, 실패: $errorCount개';
    } else {
      _dfuStatus = _deviceProgressMap.values.first.isCompleted ? 'DFU 완료!' : 'DFU 실패!';
    }
    
    _dfuProgress = 1.0;
    notifyListeners();
  }
  
  Future<void> _performSingleDfu(BluetoothDevice device, DeviceDfuProgress deviceProgress) async {
    final completer = Completer<void>();
    
    try {
      await NordicDfu().startDfu(
        device.remoteId.str,
        _selectedFirmwareFile!.path,
        onProgressChanged: (deviceAddress, percent, speed, avgSpeed, currentPart, partsTotal) {
          deviceProgress.progress = percent / 100.0;
          deviceProgress.status = '$percent%';
          
          // 전체 진행률 계산 (다중 DFU인 경우)
          if (_totalDfuDevices > 1) {
            double totalProgress = 0.0;
            for (final progress in _deviceProgressMap.values) {
              totalProgress += progress.progress;
            }
            _dfuProgress = totalProgress / _totalDfuDevices;
          } else {
            _dfuProgress = deviceProgress.progress;
          }
          
          notifyListeners();
        },
        onDfuCompleted: (deviceAddress) {
          deviceProgress.isCompleted = true;
          deviceProgress.progress = 1.0;
          deviceProgress.status = '완료';
          
          // 성공한 DFU를 히스토리에 추가
          _addToHistory(
            device,
            _selectedFirmwareFile!.path.split('/').last,
            true,
            null,
          );
          
          // DFU 성공한 기기를 선택 목록에서 제거
          _selectedDevices.removeWhere((selectedDevice) => selectedDevice.remoteId.str == device.remoteId.str);
          
          completer.complete();
        },
        onError: (deviceAddress, error, errorType, message) {
          completer.completeError(message ?? 'Unknown error');
        },
      );
    } catch (e) {
      completer.completeError(e);
    }
    
    return completer.future;
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
      _selectedDevices.clear();
      _selectedDevices.add(device);
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