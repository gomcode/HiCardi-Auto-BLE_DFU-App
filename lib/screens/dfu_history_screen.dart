import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../presentation/providers/dfu_provider.dart';
import '../presentation/providers/ble_provider.dart';
import '../core/utils/date_formatter.dart';
import 'dfu_progress_screen.dart';

class DfuHistoryScreen extends StatelessWidget {
  const DfuHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DFU 업데이트 히스토리'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, historyProvider, child) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: historyProvider.dfuHistory.isEmpty
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('히스토리 삭제'),
                              content: const Text('모든 DFU 히스토리를 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    historyProvider.clearHistory();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('삭제'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                tooltip: '히스토리 전체 삭제',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true, // 소프트버튼 영역 제외
        child: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.dfuHistory.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'DFU 업데이트 히스토리가 없습니다.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'DFU 업데이트를 실행하면 여기에 기록됩니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyProvider.dfuHistory.length,
            itemBuilder: (context, index) {
              final historyItem = historyProvider.dfuHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  historyItem.deviceName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  historyItem.zipFileName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: ${historyItem.deviceId}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (historyItem.hardwareVersionBefore != null || historyItem.hardwareVersionAfter != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    historyItem.hardwareVersionBefore != historyItem.hardwareVersionAfter
                                      ? 'H/W: ${historyItem.hardwareVersionBefore ?? 'N/A'} → ${historyItem.hardwareVersionAfter ?? 'N/A'}'
                                      : 'H/W: ${historyItem.hardwareVersionBefore ?? historyItem.hardwareVersionAfter}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: historyItem.hardwareVersionBefore != historyItem.hardwareVersionAfter
                                        ? Colors.orange[700]
                                        : Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (historyItem.firmwareVersionBefore != null || historyItem.firmwareVersionAfter != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'F/W: ${historyItem.firmwareVersionBefore ?? 'N/A'} → ${historyItem.firmwareVersionAfter ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: historyItem.firmwareVersionBefore != historyItem.firmwareVersionAfter
                                        ? Colors.blue[700]
                                        : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: historyItem.isSuccess
                                      ? Colors.green
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  historyItem.isSuccess ? '성공' : '실패',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!historyItem.isSuccess) ...[
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final bleProvider = Provider.of<BleProvider>(context, listen: false);
                                    final dfuProvider = Provider.of<DfuProvider>(context, listen: false);

                                    try {
                                      final result = await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['zip'],
                                      );

                                      if (result == null || result.files.single.path == null) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('파일 선택이 취소되었습니다')),
                                          );
                                        }
                                        return;
                                      }

                                      final firmwareFile = File(result.files.single.path!);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('기기 검색 중...'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }

                                      await bleProvider.startScan();
                                      await Future.delayed(Duration(seconds: 3));

                                      final device = bleProvider.devices.firstWhere(
                                        (d) => d.remoteId.str == historyItem.deviceId,
                                        orElse: () => throw Exception('기기를 찾을 수 없습니다'),
                                      );

                                      dfuProvider.selectFirmwareFile(firmwareFile);

                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const DfuProgressScreen()),
                                        );
                                      }

                                      await dfuProvider.startDfu([device]);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('재시도 실패: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text(
                                    '재시도',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatDateTime(historyItem.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (!historyItem.isSuccess && historyItem.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            '오류: ${historyItem.errorMessage}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }

}