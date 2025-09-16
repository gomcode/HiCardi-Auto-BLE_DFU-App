import '../constants/app_constants.dart';

class SerialValidator {
  static String sanitizeNumericInput(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool isValidSerialFormat(String deviceName) {
    final RegExp serialRegex = RegExp(r'HiCardi-[A-Z]?(\d{5})');
    return serialRegex.hasMatch(deviceName);
  }

  static String? extractSerialNumber(String deviceName) {
    final RegExp serialRegex = RegExp(r'HiCardi-[A-Z]?(\d{5})');
    final Match? match = serialRegex.firstMatch(deviceName);
    return match?.group(1);
  }

  static bool isSerialInRange(String deviceName, String? rangeStart, String? rangeEnd) {
    if ((rangeStart?.isEmpty ?? true) && (rangeEnd?.isEmpty ?? true)) {
      return true;
    }

    final String? serialNumber = extractSerialNumber(deviceName);
    if (serialNumber == null) {
      return false;
    }

    final int serial = int.tryParse(serialNumber) ?? 0;

    if (rangeStart?.isNotEmpty == true) {
      final int startSerial = int.tryParse(rangeStart!) ?? 0;
      if (serial < startSerial) return false;
    }

    if (rangeEnd?.isNotEmpty == true) {
      final int endSerial = int.tryParse(rangeEnd!) ?? 99999;
      if (serial > endSerial) return false;
    }

    return true;
  }
}