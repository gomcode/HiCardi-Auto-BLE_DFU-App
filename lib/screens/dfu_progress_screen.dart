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
        toolbarHeight: 48,
        title: Consumer<DfuProvider>(
          builder: (context, dfuProvider, child) {
            return Row(
              children: [
                const Text('DFU 진행률'),
                const Spacer(),
                Text('${dfuProvider.currentDfuIndex + 1}/${dfuProvider.totalDfuDevices}'),
              ],
            );
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: '이전',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Consumer<DfuProvider>(
            builder: (context, dfuProvider, child) {
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  height: 8,
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: dfuProvider.dfuProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Consumer<DfuProvider>(
          builder: (context, dfuProvider, child) {
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ProgressIndicatorWidget(
                      overallProgress: dfuProvider.dfuProgress,
                      status: dfuProvider.dfuStatus,
                      deviceProgressMap: dfuProvider.deviceProgressMap,
                      isMultipleDfu: dfuProvider.isMultipleDfu,
                    ),
                  ),
                ),
                if (!dfuProvider.isDfuInProgress) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}