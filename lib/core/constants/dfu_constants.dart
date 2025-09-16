class DfuConstants {
  static const String waitingStatus = '대기 중';
  static const String inProgressStatus = '진행 중';
  static const String completedStatus = '완료';
  static const String errorStatus = '오류';

  static const String dfuStarting = 'DFU 시작 중...';
  static const String dfuInProgress = 'DFU 진행 중...';
  static const String dfuCompleted = 'DFU 완료!';
  static const String dfuFailed = 'DFU 실패!';

  static const String multipleDfuStarting = '다중 DFU 시작 중...';
  static const String multipleDfuCompleted = '다중 DFU 완료!';

  static const String sharedPrefsKeyFirmwarePath = 'firmware_path';
  static const String sharedPrefsKeyDfuHistory = 'dfu_history';
}