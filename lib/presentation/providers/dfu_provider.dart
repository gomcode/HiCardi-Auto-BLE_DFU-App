import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/services/dfu_service.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/models/device_dfu_progress.dart';
import '../../data/models/dfu_history_item.dart';
import '../../core/constants/dfu_constants.dart';

class DfuProvider extends ChangeNotifier {
  final DfuService _dfuService = DfuService();

  File? _selectedFirmwareFile;
  bool _isDfuInProgress = false;
  double _dfuProgress = 0.0;
  String _dfuStatus = '';

  final Map<String, DeviceDfuProgress> _deviceProgressMap = {};
  int _currentDfuIndex = 0;
  int _totalDfuDevices = 0;

  File? get selectedFirmwareFile => _selectedFirmwareFile;
  bool get isDfuInProgress => _isDfuInProgress;
  double get dfuProgress => _dfuProgress;
  String get dfuStatus => _dfuStatus;
  Map<String, DeviceDfuProgress> get deviceProgressMap => _deviceProgressMap;
  int get currentDfuIndex => _currentDfuIndex;
  int get totalDfuDevices => _totalDfuDevices;
  bool get isMultipleDfu => _totalDfuDevices > 1;

  DfuProvider() {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final savedPath = await PreferencesRepository.loadFirmwarePath();
    if (savedPath != null) {
      _selectedFirmwareFile = File(savedPath);
      notifyListeners();
    }
  }

  void selectFirmwareFile(File file) {
    _selectedFirmwareFile = file;
    PreferencesRepository.saveFirmwarePath(file.path);
    notifyListeners();
  }

  Future<void> startDfu(List<BluetoothDevice> selectedDevices) async {
    if (selectedDevices.isEmpty || _selectedFirmwareFile == null) {
      return;
    }

    _isDfuInProgress = true;
    _currentDfuIndex = 0;
    _totalDfuDevices = selectedDevices.length;
    _deviceProgressMap.clear();

    final sortedDevices = selectedDevices.toList();
    sortedDevices.sort((a, b) => a.platformName.compareTo(b.platformName));

    for (final device in sortedDevices) {
      _deviceProgressMap[device.remoteId.str] = DeviceDfuProgress(
        deviceId: device.remoteId.str,
        deviceName: device.platformName,
      );
    }

    if (_totalDfuDevices == 1) {
      _dfuProgress = 0.0;
      _dfuStatus = DfuConstants.dfuStarting;
    } else {
      _dfuProgress = 0.0;
      _dfuStatus = '${DfuConstants.multipleDfuStarting} (총 $_totalDfuDevices개 기기)';
    }

    notifyListeners();

    await _dfuService.performMultipleDfu(
      sortedDevices,
      _selectedFirmwareFile!,
      _deviceProgressMap,
      onOverallProgress: (currentIndex, total, status) {
        _currentDfuIndex = currentIndex;
        _dfuStatus = status;
        notifyListeners();
      },
      onDeviceProgress: (deviceProgress) {
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
      onDeviceCompleted: (device, fileName) {
        _addToHistory(device, fileName, true, null);
      },
      onDeviceError: (device, fileName, error) {
        _addToHistory(device, fileName, false, error);
      },
    );

    _isDfuInProgress = false;
    final completedCount = _deviceProgressMap.values.where((p) => p.isCompleted).length;
    final errorCount = _deviceProgressMap.values.where((p) => p.isError).length;

    if (_totalDfuDevices > 1) {
      _dfuStatus = '${DfuConstants.multipleDfuCompleted} 성공: $completedCount개, 실패: $errorCount개';
    } else {
      _dfuStatus = _deviceProgressMap.values.first.isCompleted
          ? DfuConstants.dfuCompleted
          : DfuConstants.dfuFailed;
    }

    _dfuProgress = 1.0;
    notifyListeners();
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

    HistoryProvider.addHistoryItem(historyItem);
  }
}

class HistoryProvider extends ChangeNotifier {
  static List<DfuHistoryItem> _dfuHistory = [];

  List<DfuHistoryItem> get dfuHistory => _dfuHistory;

  HistoryProvider() {
    _loadDfuHistory();
  }

  Future<void> _loadDfuHistory() async {
    _dfuHistory = await PreferencesRepository.loadDfuHistory();
    notifyListeners();
  }

  static void addHistoryItem(DfuHistoryItem historyItem) {
    _dfuHistory.removeWhere((item) => item.deviceId == historyItem.deviceId);
    _dfuHistory.insert(0, historyItem);
    PreferencesRepository.saveDfuHistory(_dfuHistory);
  }

  Future<void> retryDfu(DfuHistoryItem historyItem, List<BluetoothDevice> availableDevices) async {
    final device = availableDevices.firstWhere(
      (d) => d.remoteId.str == historyItem.deviceId,
      orElse: () => throw Exception('기기를 찾을 수 없습니다. 다시 스캔해주세요.'),
    );

    final originalZipPath = await PreferencesRepository.loadFirmwarePath();
    if (originalZipPath != null && originalZipPath.endsWith(historyItem.zipFileName)) {
      throw Exception('DFU 재시도는 원본 화면에서 진행해주세요.');
    } else {
      throw Exception('원본 ZIP 파일을 찾을 수 없습니다.');
    }
  }

  void clearHistory() {
    _dfuHistory.clear();
    PreferencesRepository.clearDfuHistory();
    notifyListeners();
  }
}