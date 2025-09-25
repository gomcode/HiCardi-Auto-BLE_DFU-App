import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/ble_provider.dart';
import '../presentation/providers/dfu_provider.dart';
import '../presentation/widgets/firmware_selector_widget.dart';
import '../presentation/widgets/filter_widget.dart';
import '../presentation/widgets/device_list_widget.dart';
import '../core/constants/app_constants.dart';
import 'dfu_history_screen.dart';
import 'dfu_progress_screen.dart';

class DfuScreen extends StatelessWidget {
  const DfuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 48,
      title: const Text('HiCardi QuickDFU'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      actions: [_buildAppBarActions(context)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Consumer<DfuProvider>(
          builder: (context, dfuProvider, child) {
            return FirmwareSelectorWidget(
              selectedFile: dfuProvider.selectedFirmwareFile,
              onFileSelected: dfuProvider.selectFirmwareFile,
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBarActions(BuildContext context) {
    return Consumer2<BleProvider, HistoryProvider>(
      builder: (context, bleProvider, historyProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildScanButton(bleProvider),
            _buildProgressButton(context),
            _buildHistoryButton(context, historyProvider),
          ],
        );
      },
    );
  }

  Widget _buildScanButton(BleProvider bleProvider) {
    return IconButton(
      icon: Icon(
        bleProvider.isScanning ? Icons.search_off : Icons.search,
        color: bleProvider.isScanning ? Colors.grey : null,
      ),
      onPressed: bleProvider.isScanning ? null : bleProvider.startScan,
      tooltip: bleProvider.isScanning ? '스캔 중...' : 'BLE 스캔',
    );
  }

  Widget _buildProgressButton(BuildContext context) {
    return Consumer<DfuProvider>(
      builder: (context, dfuProvider, child) {
        if (!dfuProvider.isDfuInProgress) return const SizedBox.shrink();

        return IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DfuProgressScreen()),
          ),
          tooltip: 'DFU 진행 정보',
        );
      },
    );
  }

  Widget _buildHistoryButton(BuildContext context, HistoryProvider historyProvider) {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.history),
          if (historyProvider.dfuHistory.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                child: Text(
                  '${historyProvider.dfuHistory.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DfuHistoryScreen()),
      ),
      tooltip: 'DFU 히스토리',
    );
  }

  Widget _buildBody() {
    return Consumer<BleProvider>(
      builder: (context, bleProvider, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterWidget(
                    modelFilter: bleProvider.modelFilter,
                    serialRangeStart: bleProvider.serialRangeStart,
                    serialRangeEnd: bleProvider.serialRangeEnd,
                    onModelFilterChanged: bleProvider.setModelFilter,
                    onSerialRangeChanged: bleProvider.setSerialRange,
                  ),
                  const SizedBox(height: 12),
                  DeviceListWidget(
                    devices: bleProvider.devices,
                    selectedDevices: bleProvider.selectedDevices,
                    onDeviceToggle: bleProvider.toggleDeviceSelection,
                    onSelectAll: bleProvider.selectAllFilteredDevices,
                    onClearSelection: bleProvider.clearDeviceSelection,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Consumer2<BleProvider, DfuProvider>(
      builder: (context, bleProvider, dfuProvider, child) {
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
                if (bleProvider.selectedDevices.isEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '기기를 선택해주세요',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
                      onPressed: _canStartDfu(bleProvider, dfuProvider)
                          ? () => _startDfu(context, bleProvider, dfuProvider)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dfuProvider.isDfuInProgress
                            ? Colors.grey
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        dfuProvider.isDfuInProgress
                            ? 'DFU 진행 중...'
                            : 'DFU 업데이트 시작 (${bleProvider.selectedDevices.length}개 기기)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                const Text(
                  'V.0.0.2',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _canStartDfu(BleProvider bleProvider, DfuProvider dfuProvider) {
    return bleProvider.selectedDevices.isNotEmpty &&
           dfuProvider.selectedFirmwareFile != null &&
           !dfuProvider.isDfuInProgress;
  }

  void _startDfu(BuildContext context, BleProvider bleProvider, DfuProvider dfuProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DfuProgressScreen()),
    );

    final devicesToRemove = bleProvider.selectedDevices.toList();
    dfuProvider.startDfu(devicesToRemove);

    for (var device in devicesToRemove) {
      bleProvider.removeFromSelection(device);
    }
  }
}