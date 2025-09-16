import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final List<Permission> _requiredPermissions = [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.bluetoothAdvertise,
    Permission.location,
    Permission.storage,
  ];

  static Future<void> requestAllPermissions() async {
    await _requiredPermissions.request();
  }

  static Future<bool> areAllPermissionsGranted() async {
    for (final permission in _requiredPermissions) {
      if (!(await permission.isGranted)) {
        return false;
      }
    }
    return true;
  }
}