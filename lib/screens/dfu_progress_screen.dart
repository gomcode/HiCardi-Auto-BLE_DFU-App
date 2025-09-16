import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/dfu_provider.dart';
import '../presentation/widgets/progress_indicator_widget.dart';

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
          onPressed: () => Navigator.pop(context),
          tooltip: '이전',
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Consumer<DfuProvider>(
          builder: (context, dfuProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ProgressIndicatorWidget(
                      overallProgress: dfuProvider.dfuProgress,
                      status: dfuProvider.dfuStatus,
                      deviceProgressMap: dfuProvider.deviceProgressMap,
                      isMultipleDfu: dfuProvider.isMultipleDfu,
                    ),
                  ),
                  if (!dfuProvider.isDfuInProgress) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
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