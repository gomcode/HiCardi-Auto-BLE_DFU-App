import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import '../models/device_dfu_progress.dart';
import '../../core/constants/dfu_constants.dart';
import 'ble_service.dart';

class DfuService {
  final BleService _bleService = BleService();

  Future<void> performDfu(
    BluetoothDevice device,
    File firmwareFile,
    DeviceDfuProgress deviceProgress, {
    required Function(DeviceDfuProgress) onProgressUpdate,
    required Function(BluetoothDevice) onCompleted,
    required Function(String error) onError,
  }) async {
    final completer = Completer<void>();
    final String originalMacAddress = device.remoteId.str;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('[DFU] 기기 연결 시도 $attempt/3: ${device.platformName}');
        debugPrint('[DFU] 기기 MAC 주소: $originalMacAddress');
        await device.connect(timeout: Duration(seconds: 10));
        debugPrint('[DFU] 기기 연결 성공');

        debugPrint('[DFU] 펌웨어 버전 읽기 시작...');
        deviceProgress.firmwareVersionBefore = await _bleService.readFirmwareVersionFromConnectedDevice(device);
        debugPrint('DFU 시작 전 펌웨어 버전: ${deviceProgress.firmwareVersionBefore}');

        debugPrint('[DFU] 하드웨어 버전(Before) 읽기 시작...');
        deviceProgress.hardwareVersionBefore = await _bleService.readHardwareVersionFromConnectedDevice(device);
        debugPrint('DFU 시작 전 하드웨어 버전: ${deviceProgress.hardwareVersionBefore}');

        debugPrint('[DFU] 기기 연결 해제');
        await device.disconnect();
        break;
      } catch (e) {
        debugPrint('[오류] 시도 $attempt 실패: $e');
        try {
          await device.disconnect();
        } catch (_) {}

        if (attempt < 3) {
          debugPrint('[DFU] 2초 대기 후 재시도...');
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }

    try {
      await NordicDfu().startDfu(
        device.remoteId.str,
        firmwareFile.path,
        onProgressChanged: (deviceAddress, percent, speed, avgSpeed, currentPart, partsTotal) {
          deviceProgress.updateProgress(percent / 100.0);
          onProgressUpdate(deviceProgress);
        },
        onDfuCompleted: (deviceAddress) async {
          debugPrint('[DFU] DFU 완료! 기기 재부팅 대기 중...');
          debugPrint('[DFU] Nordic DFU가 전달한 주소: $deviceAddress');
          debugPrint('[DFU] 원래 기기 주소: $originalMacAddress');
          await Future.delayed(Duration(seconds: 3));

          try {
            debugPrint('[DFU] MAC 주소로 기기 재검색: $originalMacAddress');
            BluetoothDevice? reconnectedDevice = await _bleService.findDeviceByAddress(originalMacAddress);

            if (reconnectedDevice != null) {
              debugPrint('[DFU] 기기 재연결 중...');
              await reconnectedDevice.connect(timeout: Duration(seconds: 10));
              debugPrint('[DFU] 재연결 성공');

              try {
                await FlutterBluePlus.stopScan();
                debugPrint('[DFU] 스캔 중지');
              } catch (e) {
                debugPrint('[DFU] 스캔 중지 오류 무시: $e');
              }

              debugPrint('[DFU] 펌웨어 버전(After) 읽기 시작...');
              deviceProgress.firmwareVersionAfter = await _bleService.readFirmwareVersionFromConnectedDevice(reconnectedDevice);
              debugPrint('DFU 완료 후 펌웨어 버전: ${deviceProgress.firmwareVersionAfter}');

              debugPrint('[DFU] 하드웨어 버전(After) 읽기 시작...');
              deviceProgress.hardwareVersionAfter = await _bleService.readHardwareVersionFromConnectedDevice(reconnectedDevice);
              debugPrint('DFU 완료 후 하드웨어 버전: ${deviceProgress.hardwareVersionAfter}');

              debugPrint('[DFU] 기기 연결 해제');
              await reconnectedDevice.disconnect();
            } else {
              debugPrint('[DFU] 기기 재검색 실패');
            }
          } catch (e) {
            debugPrint('[오류] DFU 완료 후 버전 읽기 실패: $e');
          }

          deviceProgress.markAsCompleted();
          onCompleted(device);
          completer.complete();
        },
        onError: (deviceAddress, error, errorType, message) {
          final errorMsg = message ?? 'Unknown error';
          deviceProgress.markAsError(errorMsg);
          onError(errorMsg);
          completer.completeError(errorMsg);
        },
      );
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  Future<void> performMultipleDfu(
    List<BluetoothDevice> devices,
    File firmwareFile,
    Map<String, DeviceDfuProgress> progressMap, {
    required Function(int currentIndex, int total, String status) onOverallProgress,
    required Function(DeviceDfuProgress) onDeviceProgress,
    required Function(BluetoothDevice, String fileName) onDeviceCompleted,
    required Function(BluetoothDevice, String fileName, String error) onDeviceError,
  }) async {
    final sortedDevices = devices.toList();
    sortedDevices.sort((a, b) => a.platformName.compareTo(b.platformName));

    for (int i = 0; i < sortedDevices.length; i++) {
      final device = sortedDevices[i];
      final deviceProgress = progressMap[device.remoteId.str]!;
      final fileName = firmwareFile.path.split('/').last;

      deviceProgress.markAsInProgress();

      if (devices.length > 1) {
        onOverallProgress(i, devices.length,
          '기기 ${i + 1}/${devices.length}: ${device.platformName} DFU 진행 중...');
      } else {
        onOverallProgress(i, devices.length, DfuConstants.dfuInProgress);
      }

      try {
        await performDfu(
          device,
          firmwareFile,
          deviceProgress,
          onProgressUpdate: onDeviceProgress,
          onCompleted: (completedDevice) => onDeviceCompleted(completedDevice, fileName),
          onError: (error) => onDeviceError(device, fileName, error),
        );
      } catch (e) {
        continue;
      }
    }
  }
}