import 'dart:async';
import 'dart:io';
import 'dart:math';
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
      // DFU 시작 시 상태를 진행 중으로 설정
      deviceProgress.markAsInProgress();
      onProgressUpdate(deviceProgress);

      // Nordic DFU 7.0.0에서는 간단한 await 방식 사용
      print('[DFU] Starting DFU for device: ${device.remoteId.str}');

      final result = await NordicDfu().startDfu(
        device.remoteId.str,
        firmwareFile.path,
      );

      print('[DFU] DFU result: $result');

      if (result != null) {
        print('[DFU] DFU completed successfully');
        deviceProgress.markAsCompleted();
        deviceProgress.progress = 1.0;
        onProgressUpdate(deviceProgress);
        onCompleted(device);
        if (!completer.isCompleted) {
          completer.complete();
        }
      } else {
        print('[DFU] DFU failed or cancelled');
        deviceProgress.markAsError('DFU 실패 또는 취소됨');
        onProgressUpdate(deviceProgress);
        onError('DFU 실패 또는 취소됨');
        if (!completer.isCompleted) {
          completer.completeError('DFU 실패 또는 취소됨');
        }
      }
    } catch (e) {
      if (!completer.isCompleted) {
        final errorMsg = 'DFU 시작 실패: $e';
        deviceProgress.markAsError(errorMsg);
        onError(errorMsg);
        completer.completeError(e);
      }
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
      final fileName = firmwareFile.path.split(Platform.pathSeparator).last;

      // markAsInProgress는 performDfu에서 처리됨

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
        print('[DFU] Device ${device.platformName} failed: $e');
        final deviceProgress = progressMap[device.remoteId.str]!;
        deviceProgress.markAsError('DFU 실패: $e');
        onDeviceError(device, fileName, 'DFU 실패: $e');
        continue;
      }
    }
  }

  Future<void> performConcurrentDfu(
    List<BluetoothDevice> devices,
    File firmwareFile,
    Map<String, DeviceDfuProgress> progressMap, {
    int maxConcurrentDevices = 8,
    required Function(String status) onOverallProgress,
    required Function(DeviceDfuProgress) onDeviceProgress,
    required Function(BluetoothDevice, String fileName) onDeviceCompleted,
    required Function(BluetoothDevice, String fileName, String error) onDeviceError,
  }) async {
    final sortedDevices = devices.toList();
    sortedDevices.sort((a, b) => a.platformName.compareTo(b.platformName));

    final fileName = firmwareFile.path.split(Platform.pathSeparator).last;

    // 배치로 나누어서 처리
    final batches = <List<BluetoothDevice>>[];
    for (int i = 0; i < sortedDevices.length; i += maxConcurrentDevices) {
      final end = min(i + maxConcurrentDevices, sortedDevices.length);
      batches.add(sortedDevices.sublist(i, end));
    }

    int completedBatches = 0;

    for (final batch in batches) {
      final batchIndex = completedBatches + 1;
      final totalBatches = batches.length;

      onOverallProgress(
        'DFU 진행 중 - 배치 $batchIndex/$totalBatches (${batch.length}개 기기 동시 처리)'
      );

      // markAsInProgress는 performDfu에서 개별적으로 처리됨

      // 병렬로 DFU 수행
      final futures = batch.map((device) async {
        final deviceProgress = progressMap[device.remoteId.str]!;

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
          // 개별 기기 에러는 onError 콜백에서 처리됨
        }
      }).toList();

      // 현재 배치의 모든 DFU가 완료될 때까지 대기
      await Future.wait(futures);

      completedBatches++;

      // 배치 완료 상태 업데이트
      if (completedBatches < batches.length) {
        onOverallProgress(
          '배치 $batchIndex/$totalBatches 완료. 다음 배치 준비 중...'
        );
        // 다음 배치 전 잠시 대기 (옵션)
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // 전체 완료 상태
    final completedCount = progressMap.values.where((p) => p.isCompleted).length;
    final errorCount = progressMap.values.where((p) => p.isError).length;

    onOverallProgress(
      '${DfuConstants.multipleDfuCompleted} 성공: $completedCount개, 실패: $errorCount개'
    );
  }
}