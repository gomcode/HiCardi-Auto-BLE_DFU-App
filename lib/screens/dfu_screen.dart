import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/dfu_provider.dart';
import 'dfu_history_screen.dart';
import 'dfu_progress_screen.dart';

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
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BLE 스캔 버튼 (돋보기 아이콘)
                  IconButton(
                    icon: Icon(
                      dfuProvider.isScanning ? Icons.search_off : Icons.search,
                      color: dfuProvider.isScanning ? Colors.grey : null,
                    ),
                    onPressed: dfuProvider.isScanning ? null : () => dfuProvider.startScan(),
                    tooltip: dfuProvider.isScanning ? '스캔 중...' : 'BLE 스캔',
                  ),
                  // DFU 진행중 정보 버튼
                  if (dfuProvider.isDfuInProgress)
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DfuProgressScreen(),
                          ),
                        );
                      },
                      tooltip: 'DFU 진행 정보',
                    ),
                  // 히스토리 버튼
                  IconButton(
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
                  ),
                ],
              );
            },
          ),
        ],
        // 펌웨어 파일 선택 영역을 AppBar 하단에 고정
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Consumer<DfuProvider>(
            builder: (context, dfuProvider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.folder_zip, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dfuProvider.selectedFirmwareFile != null
                            ? dfuProvider.selectedFirmwareFile!.path.split('/').last
                            : '펌웨어 파일을 선택하세요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: dfuProvider.selectedFirmwareFile != null 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: dfuProvider.selectedFirmwareFile != null 
                              ? Colors.blue 
                              : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.attach_file, size: 20),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['zip'],
                        );
                        if (result != null) {
                          dfuProvider.selectFirmwareFile(File(result.files.single.path!));
                        }
                      },
                      tooltip: 'ZIP 파일 선택',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        bottom: true, // 소프트버튼 영역 제외
        child: Consumer<DfuProvider>(
          builder: (context, dfuProvider, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 기기 필터링 및 선택 섹션 (확대)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        
                        // 모델 및 시리얼 범위 필터 (한 줄)
                        Row(
                          children: [
                            const Text('모델: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Expanded(
                              flex: 2,
                              child: DropdownButton<String>(
                                value: dfuProvider.modelFilter,
                                onChanged: (String? newValue) {
                                  dfuProvider.setModelFilter(newValue!);
                                },
                                items: <String>['전체', 'HiCardi-', 'HiCardi-A', 'HiCardi-C', 'HiCardi-D', 'HiCardi-E', 'HiCardi-M', 'HiCardi-N']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('시리얼: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: '시작',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  labelStyle: TextStyle(fontSize: 10),
                                ),
                                style: const TextStyle(fontSize: 12),
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                onChanged: (value) {
                                  // 숫자만 입력 허용
                                  final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (numericValue != value) {
                                    // 숫자가 아닌 문자가 입력된 경우 제거
                                    return;
                                  }
                                  dfuProvider.setSerialRange(numericValue, dfuProvider.serialRangeEnd);
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('~', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: '끝',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  labelStyle: TextStyle(fontSize: 10),
                                ),
                                style: const TextStyle(fontSize: 12),
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                onChanged: (value) {
                                  // 숫자만 입력 허용
                                  final numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                                  if (numericValue != value) {
                                    // 숫자가 아닌 문자가 입력된 경우 제거
                                    return;
                                  }
                                  dfuProvider.setSerialRange(dfuProvider.serialRangeStart, numericValue);
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
                        
                        // 기기 목록 (확대)
                        SizedBox(
                          height: 400,
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

              ],
            ),
          );
        },
        ),
      ),
      bottomNavigationBar: Consumer<DfuProvider>(
        builder: (context, dfuProvider, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dfuProvider.selectedDevices.isEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '기기를 선택해주세요',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ] else ...[
                    if (dfuProvider.dfuStatus.isNotEmpty) ...[
                    Text(
                      dfuProvider.dfuStatus,
                      style: TextStyle(
                        color: dfuProvider.dfuStatus.contains('완료') 
                            ? Colors.green 
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (dfuProvider.selectedDevices.isNotEmpty && 
                                   dfuProvider.selectedFirmwareFile != null &&
                                   !dfuProvider.isDfuInProgress) // DFU 진행중이 아닐 때만 활성화
                            ? () async {
                                // DFU 시작과 동시에 progress 화면으로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DfuProgressScreen(),
                                  ),
                                );
                                await dfuProvider.startDfu();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dfuProvider.isDfuInProgress ? Colors.grey : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          dfuProvider.isDfuInProgress 
                              ? 'DFU 진행 중...' 
                              : 'DFU 업데이트 시작 (${dfuProvider.selectedDevices.length}개 기기)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  // 앱 버전 정보 표시
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text(
                        'V1.0.0',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}