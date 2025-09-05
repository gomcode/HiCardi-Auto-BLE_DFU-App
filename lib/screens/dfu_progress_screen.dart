import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dfu_provider.dart';

class DfuProgressScreen extends StatelessWidget {
  const DfuProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DFU 진행률'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: '이전',
        ),
      ),
      body: SafeArea(
        bottom: true, // 소프트버튼 영역 제외
        child: Consumer<DfuProvider>(
          builder: (context, dfuProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 전체 진행률 표시
                  Card(
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
                          LinearProgressIndicator(value: dfuProvider.dfuProgress),
                          const SizedBox(height: 8),
                          Text(
                            dfuProvider.dfuStatus,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 기기별 진행률 표시
                  if (dfuProvider.isMultipleDfu) ...[
                    const Text(
                      '기기별 진행률',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: dfuProvider.deviceProgressMap.length,
                        itemBuilder: (context, index) {
                          final deviceProgress = dfuProvider.deviceProgressMap.values.elementAt(index);
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                                  : Colors.blue,
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
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      deviceProgress.isCompleted
                                          ? Colors.green
                                          : deviceProgress.isError
                                              ? Colors.red
                                              : Colors.blue,
                                    ),
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
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // 단일 기기 DFU인 경우
                    if (dfuProvider.deviceProgressMap.isNotEmpty) ...[
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
                                dfuProvider.deviceProgressMap.values.first.deviceName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'MAC 주소: ${dfuProvider.deviceProgressMap.values.first.deviceId}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                  
                  // DFU 완료 후 닫기 버튼
                  if (!dfuProvider.isDfuInProgress) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}