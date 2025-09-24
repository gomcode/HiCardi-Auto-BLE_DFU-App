import '../../core/constants/dfu_constants.dart';

class DeviceDfuProgress {
  final String deviceId;
  final String deviceName;
  double progress;
  String status;
  bool isCompleted;
  bool isError;
  String? errorMessage;

  DeviceDfuProgress({
    required this.deviceId,
    required this.deviceName,
    this.progress = 0.0,
    this.status = DfuConstants.waitingStatus,
    this.isCompleted = false,
    this.isError = false,
    this.errorMessage,
  });

  void updateProgress(double newProgress) {
    progress = newProgress;
    status = '${(newProgress * 100).toInt()}%';
  }

  void markAsCompleted() {
    isCompleted = true;
    progress = 1.0;
    status = DfuConstants.completedStatus;
  }

  void markAsError(String error) {
    isError = true;
    status = DfuConstants.errorStatus;
    errorMessage = error;
  }

  void markAsInProgress() {
    status = DfuConstants.inProgressStatus;
  }

  bool get isInProgress => status == DfuConstants.inProgressStatus;
}