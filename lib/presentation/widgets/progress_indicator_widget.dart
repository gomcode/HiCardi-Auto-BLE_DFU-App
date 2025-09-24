import 'package:flutter/material.dart';
import '../../data/models/device_dfu_progress.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double overallProgress;
  final String status;
  final Map<String, DeviceDfuProgress> deviceProgressMap;
  final bool isMultipleDfu;
  final bool isParallelMode;

  const ProgressIndicatorWidget({
    super.key,
    required this.overallProgress,
    required this.status,
    required this.deviceProgressMap,
    required this.isMultipleDfu,
    this.isParallelMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOverallProgress(),
        const SizedBox(height: 16),
        if (isMultipleDfu) _buildMultipleDeviceProgress()
        else _buildSingleDeviceProgress(),
      ],
    );
  }

  Widget _buildOverallProgress() {
    // 병렬 모드에서는 실시간 진행률 재계산
    double actualProgress = overallProgress;
    if (isParallelMode && deviceProgressMap.isNotEmpty) {
      double totalProgress = 0.0;
      int validDevices = 0;

      for (final progress in deviceProgressMap.values) {
        totalProgress += progress.progress;
        validDevices++;
      }

      // validDevices로 나누어 DfuProvider의 계산과 일치시킴
      actualProgress = validDevices > 0 ? totalProgress / validDevices : 0.0;
    }

    // NaN 방지
    actualProgress = actualProgress.isNaN ? 0.0 : actualProgress.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '전체 진행률',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_safeProgressPercent(actualProgress)}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: actualProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getOverallProgressColor()),
            ),
            const SizedBox(height: 8),
            Text(status, style: const TextStyle(fontSize: 14)),
            if (isParallelMode && deviceProgressMap.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '병렬 모드 - ${deviceProgressMap.length}개 기기',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getOverallProgressColor() {
    if (deviceProgressMap.isEmpty) return Colors.blue;

    final completedCount = deviceProgressMap.values.where((p) => p.isCompleted).length;
    final errorCount = deviceProgressMap.values.where((p) => p.isError).length;
    final totalCount = deviceProgressMap.length;

    if (completedCount == totalCount) return Colors.green;
    if (errorCount > 0) return Colors.orange;
    return Colors.blue;
  }

  Widget _buildMultipleDeviceProgress() {
    // 기기를 상태별로 정렬: 진행중 -> 완료 -> 오류 -> 대기 순서
    final sortedDevices = deviceProgressMap.values.toList()
      ..sort((a, b) {
        if (a.isInProgress && !b.isInProgress) return -1;
        if (!a.isInProgress && b.isInProgress) return 1;
        if (a.isCompleted && !b.isCompleted) return -1;
        if (!a.isCompleted && b.isCompleted) return 1;
        if (a.isError && !b.isError) return -1;
        if (!a.isError && b.isError) return 1;
        return a.deviceName.compareTo(b.deviceName);
      });

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '기기별 진행률',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildDeviceCountSummary(),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: sortedDevices.length,
              itemBuilder: (context, index) {
                return _DeviceProgressCard(deviceProgress: sortedDevices[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCountSummary() {
    final completedCount = deviceProgressMap.values.where((p) => p.isCompleted).length;
    final errorCount = deviceProgressMap.values.where((p) => p.isError).length;
    final inProgressCount = deviceProgressMap.values.where((p) => p.isInProgress).length;
    final totalCount = deviceProgressMap.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '완료: $completedCount, 진행: $inProgressCount, 오류: $errorCount / $totalCount',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildSingleDeviceProgress() {
    if (deviceProgressMap.isEmpty) return const SizedBox.shrink();

    final deviceProgress = deviceProgressMap.values.first;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기기 진행률',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          deviceProgress.deviceName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSingleDeviceProgressColor(deviceProgress),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          deviceProgress.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MAC 주소: ${deviceProgress.deviceId}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: deviceProgress.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_getSingleDeviceProgressColor(deviceProgress)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_safeProgressPercent(deviceProgress.progress)}%',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (deviceProgress.isError && deviceProgress.errorMessage != null)
                        Expanded(
                          child: Text(
                            '오류: ${deviceProgress.errorMessage}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSingleDeviceProgressColor(DeviceDfuProgress deviceProgress) {
    if (deviceProgress.isCompleted) return Colors.green;
    if (deviceProgress.isError) return Colors.red;
    return Colors.blue;
  }

  int _safeProgressPercent(double progress) {
    if (progress.isNaN || progress.isInfinite) return 0;
    return (progress.clamp(0.0, 1.0) * 100).round();
  }
}

class _DeviceProgressCard extends StatelessWidget {
  final DeviceDfuProgress deviceProgress;

  const _DeviceProgressCard({required this.deviceProgress});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    deviceProgress.deviceName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: deviceProgress.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            ),
            const SizedBox(height: 4),
            Text(
              '${_safeProgressPercent(deviceProgress.progress)}%',
              style: const TextStyle(fontSize: 12),
            ),
            if (deviceProgress.isError && deviceProgress.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                '오류: ${deviceProgress.errorMessage}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getProgressColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        deviceProgress.status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getProgressColor() {
    if (deviceProgress.isCompleted) return Colors.green;
    if (deviceProgress.isError) return Colors.red;
    return Colors.blue;
  }

  int _safeProgressPercent(double progress) {
    if (progress.isNaN || progress.isInfinite) return 0;
    return (progress.clamp(0.0, 1.0) * 100).round();
  }
}