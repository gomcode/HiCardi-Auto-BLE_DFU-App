import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/dfu_provider.dart';

class DfuScreen extends StatefulWidget {
  const DfuScreen({super.key});

  @override
  State<DfuScreen> createState() => _DfuScreenState();
}

class _DfuScreenState extends State<DfuScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
      Permission.storage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nordic Auto DFU'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<DfuProvider>(
        builder: (context, dfuProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BLE 스캔 섹션
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. BLE 기기 스캔',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: dfuProvider.isScanning ? null : () => dfuProvider.startScan(),
                          child: Text(dfuProvider.isScanning ? '스캔 중...' : 'BLE 스캔 시작'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 기기 선택 섹션
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2. 기기 선택',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (dfuProvider.selectedDevice != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '선택된 기기: ${dfuProvider.selectedDevice!.platformName}\n${dfuProvider.selectedDevice!.remoteId}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            itemCount: dfuProvider.devices.length,
                            itemBuilder: (context, index) {
                              final device = dfuProvider.devices[index];
                              return ListTile(
                                title: Text(device.platformName.isEmpty ? '알 수 없는 기기' : device.platformName),
                                subtitle: Text(device.remoteId.str),
                                trailing: dfuProvider.selectedDevice == device
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : null,
                                onTap: () => dfuProvider.selectDevice(device),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 펌웨어 파일 선택 섹션
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3. 펌웨어 파일 선택',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (dfuProvider.selectedFirmwareFile != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '선택된 파일: ${dfuProvider.selectedFirmwareFile!.path.split('/').last}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['zip'],
                            );
                            if (result != null) {
                              dfuProvider.selectFirmwareFile(File(result.files.single.path!));
                            }
                          },
                          child: const Text('ZIP 파일 선택'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // DFU 실행 섹션
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '4. DFU 업데이트',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (dfuProvider.isDfuInProgress) ...[
                          LinearProgressIndicator(value: dfuProvider.dfuProgress),
                          const SizedBox(height: 8),
                          Text(dfuProvider.dfuStatus),
                        ] else ...[
                          ElevatedButton(
                            onPressed: (dfuProvider.selectedDevice != null && 
                                       dfuProvider.selectedFirmwareFile != null)
                                ? () => dfuProvider.startDfu()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('DFU 업데이트 시작'),
                          ),
                          if (dfuProvider.dfuStatus.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              dfuProvider.dfuStatus,
                              style: TextStyle(
                                color: dfuProvider.dfuStatus.contains('완료') 
                                    ? Colors.green 
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}