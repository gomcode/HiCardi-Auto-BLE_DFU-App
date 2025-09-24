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

  Future<String?> readFirmwareVersionFromConnectedDevice(BluetoothDevice device) async {
    try {
      debugPrint('=== 연결된 기기에서 펌웨어 버전 읽기: ${device.platformName} ===');

      List<BluetoothService> services = await device.discoverServices();
      debugPrint('발견된 서비스 수: ${services.length}');

      for (BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toUpperCase().replaceAll('-', '');
        debugPrint('서비스 UUID: $serviceUuid');
        if (serviceUuid.contains('F36414000') && serviceUuid.contains('B04240BA5005CA45BF8ABC')) {
          debugPrint('펌웨어 서비스 발견!');
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toUpperCase().replaceAll('-', '');
            debugPrint('Characteristic UUID: $charUuid');
            if (charUuid.contains('F36414030') && charUuid.contains('B04240BA5005CA45BF8ABC')) {
              debugPrint('펌웨어 버전 Characteristic 발견!');
              List<int> value = await characteristic.read();
              debugPrint('읽은 값 (hex): $value');

              String asciiVersion = String.fromCharCodes(value.where((byte) => byte != 0));
              debugPrint('변환된 펌웨어 버전: $asciiVersion');

              return asciiVersion;
            }
          }
        }
      }

      debugPrint('펌웨어 버전 Characteristic을 찾지 못함');
      return null;
    } catch (e) {
      debugPrint('펌웨어 버전 읽기 오류: $e');
      return null;
    }
  }

  Future<String?> readHardwareVersionFromConnectedDevice(BluetoothDevice device) async {
    try {
      debugPrint('=== 연결된 기기에서 하드웨어 버전 읽기: ${device.platformName} ===');

      List<BluetoothService> services = await device.discoverServices();
      debugPrint('발견된 서비스 수: ${services.length}');

      for (BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toUpperCase().replaceAll('-', '');
        debugPrint('서비스 UUID: $serviceUuid');
        if (serviceUuid.contains('F36414000') && serviceUuid.contains('B04240BA5005CA45BF8ABC')) {
          debugPrint('하드웨어 서비스 발견!');
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toUpperCase().replaceAll('-', '');
            debugPrint('Characteristic UUID: $charUuid');
            if (charUuid.contains('F36414020') && charUuid.contains('B04240BA5005CA45BF8ABC')) {
              debugPrint('하드웨어 버전 Characteristic 발견!');
              List<int> value = await characteristic.read();
              debugPrint('읽은 값 (hex): $value');

              String asciiVersion = String.fromCharCodes(value.where((byte) => byte != 0));
              debugPrint('변환된 하드웨어 버전: $asciiVersion');

              return asciiVersion;
            }
          }
        }
      }

      debugPrint('하드웨어 버전 Characteristic을 찾지 못함');
      return null;
    } catch (e) {
      debugPrint('하드웨어 버전 읽기 오류: $e');
      return null;
    }
  }

  Future<BluetoothDevice?> findDeviceByAddress(String address) async {
    try {
      debugPrint('=== MAC 주소로 기기 검색: $address ===');

      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      for (var device in connectedDevices) {
        if (device.remoteId.str == address) {
          debugPrint('연결된 기기에서 발견: ${device.platformName}');
          return device;
        }
      }

      for (int attempt = 1; attempt <= 3; attempt++) {
        debugPrint('스캔 시도 $attempt/3');

        try {
          await FlutterBluePlus.stopScan();
        } catch (e) {
          debugPrint('기존 스캔 중지 오류 무시: $e');
        }

        await Future.delayed(Duration(milliseconds: 500));

        BluetoothDevice? foundDevice;
        StreamSubscription? subscription;

        try {
          subscription = FlutterBluePlus.scanResults.listen((scanResults) async {
            if (foundDevice != null) return;

            for (var result in scanResults) {
              if (foundDevice != null) break;

              String scannedMac = result.device.remoteId.str.toUpperCase().replaceAll(':', '');
              String targetMac = address.toUpperCase().replaceAll(':', '');
              if (scannedMac == targetMac) {
                debugPrint('>>> 찾는 기기 발견! ${result.device.platformName} (${result.device.remoteId.str})');
                foundDevice = result.device;
                await subscription?.cancel();
                await FlutterBluePlus.stopScan();
                debugPrint('스캔 즉시 중지!');
              }
            }
          });

          debugPrint('스캔 시작...');
          await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

          for (int i = 0; i < 50; i++) {
            await Future.delayed(Duration(milliseconds: 100));
            if (foundDevice != null) {
              debugPrint('기기 찾음! 대기 중단');
              break;
            }
          }

          debugPrint('스캔 완료, foundDevice: ${foundDevice?.platformName ?? "null"}');

          try {
            await subscription.cancel();
            await FlutterBluePlus.stopScan();
          } catch (e) {
            debugPrint('스캔 정리 오류 무시: $e');
          }

          if (foundDevice != null) {
            return foundDevice;
          }
        } catch (e) {
          debugPrint('스캔 중 오류: $e');
          try {
            await FlutterBluePlus.stopScan();
            await subscription?.cancel();
          } catch (_) {}
        }

        if (attempt < 3) {
          debugPrint('기기 못 찾음, 2초 후 재시도...');
          await Future.delayed(Duration(seconds: 2));
        }
      }

      debugPrint('기기를 찾지 못함 (3회 시도 후)');
      return null;
    } catch (e) {
      debugPrint('기기 검색 오류: $e');
      return null;
    }
  }

  void dispose() {
    _scanUpdateTimer?.cancel();
    _devicesController.close();
  }
}