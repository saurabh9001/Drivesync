import 'package:permission_handler/permission_handler.dart';

class EmergencyPermissionService {
  EmergencyPermissionService._internal();

  static final EmergencyPermissionService _instance = EmergencyPermissionService._internal();

  factory EmergencyPermissionService() => _instance;

  Future<bool> ensureCriticalPermissions({bool request = true}) async {
    final results = await Future.wait<bool>([
      ensureSmsPermission(request: request),
      ensurePhonePermission(request: request),
      ensureLocationPermission(request: request),
    ]);
    return results.every((granted) => granted);
  }

  Future<bool> ensureSmsPermission({bool request = true}) async {
    return _ensurePermission(
      permission: Permission.sms,
      request: request,
      label: 'SMS',
    );
  }

  Future<bool> ensurePhonePermission({bool request = true}) async {
    return _ensurePermission(
      permission: Permission.phone,
      request: request,
      label: 'Phone',
    );
  }

  Future<bool> ensureLocationPermission({bool request = true}) async {
    return _ensurePermission(
      permission: Permission.location,
      request: request,
      label: 'Location',
    );
  }

  Future<bool> _ensurePermission({
    required Permission permission,
    required bool request,
    required String label,
  }) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) {
      _log('$label permission already granted.');
      return true;
    }

    _log('$label permission status: $status');

    if (!request || status.isPermanentlyDenied) {
      if (status.isPermanentlyDenied) {
        _log('$label permission permanently denied. Prompting user to open settings.');
        await openAppSettings();
      }
      return false;
    }

    status = await permission.request();
    _log('$label permission request result: $status');
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      _log('$label permission permanently denied after request. Opening app settings.');
      await openAppSettings();
    }
    return false;
  }

  void _log(String message) {
    // ignore: avoid_print
    print('🔐 [EmergencyPermissionService] $message');
  }
}
