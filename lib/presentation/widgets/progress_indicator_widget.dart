import 'package:flutter/material.dart';
import '../../data/models/device_dfu_progress.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double overallProgress;
  final String status;
  final Map<String, DeviceDfuProgress> deviceProgressMap;
  final bool isMultipleDfu;

  const ProgressIndicatorWidget({
    super.key,
    required this.overallProgress,
    required this.status,
    required this.deviceProgressMap,
    required this.isMultipleDfu,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '전체 진행률',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: overallProgress),
            const SizedBox(height: 8),
            Text(status, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleDeviceProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기기별 진행률',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...deviceProgressMap.values.map((deviceProgress) =>
          _DeviceProgressCard(deviceProgress: deviceProgress)
        ),
      ],
    );
  }

  Widget _buildSingleDeviceProgress() {
    if (deviceProgressMap.isEmpty) return const SizedBox.shrink();

    final deviceProgress = deviceProgressMap.values.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기기 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceProgress.deviceName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'MAC 주소: ${deviceProgress.deviceId}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
              '${(deviceProgress.progress * 100).toInt()}%',
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
}