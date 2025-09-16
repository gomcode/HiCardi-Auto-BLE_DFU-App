import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/constants/app_constants.dart';

class DeviceListWidget extends StatelessWidget {
  final List<BluetoothDevice> devices;
  final List<BluetoothDevice> selectedDevices;
  final Function(BluetoothDevice) onDeviceToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  const DeviceListWidget({
    super.key,
    required this.devices,
    required this.selectedDevices,
    required this.onDeviceToggle,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedDevices.isNotEmpty) _buildSelectedDevicesInfo(),
        const SizedBox(height: 8),
        if (devices.isNotEmpty) _buildControlButtons(),
        const SizedBox(height: 8),
        _buildDeviceList(),
      ],
    );
  }

  Widget _buildSelectedDevicesInfo() {
    final sortedDevices = selectedDevices.toList();
    sortedDevices.sort((a, b) => a.platformName.compareTo(b.platformName));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선택된 기기 (${selectedDevices.length}개):',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...sortedDevices.map((device) => Text(
            '• ${device.platformName} (${device.remoteId.str})',
            style: const TextStyle(fontSize: 12),
          )),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: onSelectAll,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('전체 선택'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onClearSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: const Text('선택 해제'),
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    return SizedBox(
      height: AppConstants.deviceListHeight.toDouble(),
      child: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          final isSelected = selectedDevices.contains(device);
          return ListTile(
            title: Text(
              device.platformName.isEmpty ? '알 수 없는 기기' : device.platformName,
            ),
            subtitle: Text(device.remoteId.str),
            trailing: isSelected
                ? const Icon(Icons.check_box, color: Colors.green)
                : const Icon(Icons.check_box_outline_blank),
            onTap: () => onDeviceToggle(device),
          );
        },
      ),
    );
  }
}