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
    if (isMultipleDfu) {
      return _buildMultipleDeviceProgressWithFixedHeader();
    } else {
      return _buildSingleDeviceProgressWithFixedHeader();
    }
  }



  Widget _buildMultipleDeviceProgressWithFixedHeader() {
    return ListView.builder(
      itemCount: deviceProgressMap.length,
      itemBuilder: (context, index) {
        final deviceProgress = deviceProgressMap.values.elementAt(index);
        return _DeviceProgressCard(deviceProgress: deviceProgress);
      },
    );
  }

  Widget _buildSingleDeviceProgressWithFixedHeader() {
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
        _DeviceProgressCard(deviceProgress: deviceProgress),
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
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
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
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: deviceProgress.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            ),
            if (deviceProgress.hardwareVersionBefore != null || deviceProgress.firmwareVersionBefore != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (deviceProgress.hardwareVersionBefore != null)
                    Expanded(
                      child: Text(
                        'H/W: ${deviceProgress.hardwareVersionBefore}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (deviceProgress.firmwareVersionBefore != null)
                    Expanded(
                      child: Text(
                        'F/W: ${deviceProgress.firmwareVersionBefore}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
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
    if (deviceProgress.isCompleted) return Colors.blue;
    if (deviceProgress.isError) return Colors.red;
    return Colors.green;
  }
}