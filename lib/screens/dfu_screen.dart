import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/dfu_provider.dart';
import 'dfu_history_screen.dart';

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
        actions: [
          Consumer<DfuProvider>(
            builder: (context, dfuProvider, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.history),
                    if (dfuProvider.dfuHistory.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '${dfuProvider.dfuHistory.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DfuHistoryScreen(),
                    ),
                  );
                },
                tooltip: 'DFU 히스토리',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<DfuProvider>(
          builder: (context, dfuProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 펌웨어 파일 선택 섹션
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1. 펌웨어 파일 선택',
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
                
                // 2. BLE 기기 스캔 섹션
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2. BLE 기기 스캔',
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
                
                // 3. 기기 필터링 및 선택 섹션
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3. 기기 필터링 및 선택',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        // 모델 필터 드롭다운
                        Row(
                          children: [
                            const Text('모델: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: dfuProvider.modelFilter,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: '전체', child: Text('전체')),
                                  DropdownMenuItem(value: 'HiCardi-', child: Text('HiCardi- (기본형)')),
                                  DropdownMenuItem(value: 'HiCardi-A', child: Text('HiCardi-A')),
                                  DropdownMenuItem(value: 'HiCardi-C', child: Text('HiCardi-C')),
                                  DropdownMenuItem(value: 'HiCardi-D', child: Text('HiCardi-D')),
                                  DropdownMenuItem(value: 'HiCardi-E', child: Text('HiCardi-E')),
                                  DropdownMenuItem(value: 'HiCardi-M', child: Text('HiCardi-M')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    dfuProvider.setModelFilter(value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // 시리얼 번호 범위 필터
                        Row(
                          children: [
                            const Text('시리얼 범위: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: '시작 (예: 00001)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                onChanged: (value) {
                                  dfuProvider.setSerialRange(value, dfuProvider.serialRangeEnd);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('~'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: '끝 (예: 99999)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                onChanged: (value) {
                                  dfuProvider.setSerialRange(dfuProvider.serialRangeStart, value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // 선택된 기기 표시
                         if (dfuProvider.selectedDevices.isNotEmpty)
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.green.shade100,
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   '선택된 기기 (${dfuProvider.selectedDevices.length}개):',
                                   style: const TextStyle(fontWeight: FontWeight.bold),
                                 ),
                                 const SizedBox(height: 4),
                                 // 기기 이름 오름차순으로 정렬하여 표시
                                  ...(() {
                                    final sortedDevices = dfuProvider.selectedDevices.toList();
                                    sortedDevices.sort((a, b) => a.platformName.compareTo(b.platformName));
                                    return sortedDevices.map((device) => Text(
                                      '• ${device.platformName} (${device.remoteId.str})',
                                      style: const TextStyle(fontSize: 12),
                                    ));
                                  })(),
                               ],
                             ),
                           ),
                        const SizedBox(height: 8),
                        
                        // 전체 선택/해제 버튼
                        if (dfuProvider.devices.isNotEmpty)
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => dfuProvider.selectAllFilteredDevices(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('전체 선택'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => dfuProvider.clearDeviceSelection(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('선택 해제'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        
                        // 기기 목록
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: dfuProvider.devices.length,
                            itemBuilder: (context, index) {
                              final device = dfuProvider.devices[index];
                              final isSelected = dfuProvider.selectedDevices.contains(device);
                              return ListTile(
                                title: Text(device.platformName.isEmpty ? '알 수 없는 기기' : device.platformName),
                                subtitle: Text(device.remoteId.str),
                                trailing: isSelected
                                    ? const Icon(Icons.check_box, color: Colors.green)
                                    : const Icon(Icons.check_box_outline_blank),
                                onTap: () => dfuProvider.toggleDeviceSelection(device),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 4. DFU 업데이트 섹션
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
                          // 전체 진행률 표시
                          LinearProgressIndicator(value: dfuProvider.dfuProgress),
                          const SizedBox(height: 8),
                          Text(dfuProvider.dfuStatus),
                          const SizedBox(height: 16),
                          
                          // 다중 DFU인 경우 각 기기별 진행률 표시
                          if (dfuProvider.isMultipleDfu) ...[
                            const Text(
                              '기기별 진행률:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...dfuProvider.deviceProgressMap.values.map((deviceProgress) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: deviceProgress.isCompleted
                                      ? Colors.green.shade50
                                      : deviceProgress.isError
                                          ? Colors.red.shade50
                                          : Colors.blue.shade50,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            deviceProgress.deviceName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: deviceProgress.isCompleted
                                                ? Colors.green
                                                : deviceProgress.isError
                                                    ? Colors.red
                                                    : deviceProgress.status == '진행 중'
                                                        ? Colors.blue
                                                        : Colors.grey,
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
                                    LinearProgressIndicator(
                                      value: deviceProgress.progress,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        deviceProgress.isCompleted
                                            ? Colors.green
                                            : deviceProgress.isError
                                                ? Colors.red
                                                : Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'ID: ${deviceProgress.deviceId}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${(deviceProgress.progress * 100).toInt()}%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (deviceProgress.isError && deviceProgress.errorMessage != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.red.shade300),
                                        ),
                                        child: Text(
                                          '오류: ${deviceProgress.errorMessage}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ] else ...[
                          ElevatedButton(
                            onPressed: (dfuProvider.selectedDevices.isNotEmpty && 
                                       dfuProvider.selectedFirmwareFile != null)
                                ? () => dfuProvider.startDfu()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              dfuProvider.selectedDevices.isEmpty
                                  ? 'DFU 업데이트 시작 (기기를 선택하세요)'
                                  : 'DFU 업데이트 시작 (${dfuProvider.selectedDevices.length}개 기기)',
                            ),
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
      ),
    );
  }
}