import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import '../models/device_dfu_progress.dart';
import '../../core/constants/dfu_constants.dart';

class DfuService {
  Future<void> performDfu(
    BluetoothDevice device,
    File firmwareFile,
    DeviceDfuProgress deviceProgress, {
    required Function(DeviceDfuProgress) onProgressUpdate,
    required Function(BluetoothDevice) onCompleted,
    required Function(String error) onError,
  }) async {
    final completer = Completer<void>();

    try {
      await NordicDfu().startDfu(
        device.remoteId.str,
        firmwareFile.path,
        onProgressChanged: (deviceAddress, percent, speed, avgSpeed, currentPart, partsTotal) {
          deviceProgress.updateProgress(percent / 100.0);
          onProgressUpdate(deviceProgress);
        },
        onDfuCompleted: (deviceAddress) {
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