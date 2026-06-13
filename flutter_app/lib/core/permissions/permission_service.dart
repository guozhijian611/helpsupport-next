import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionStatus> notificationStatus() {
    return Permission.notification.status;
  }

  Future<PermissionStatus> requestNotifications() {
    return Permission.notification.request();
  }

  Future<PermissionStatus> cameraStatus() {
    return Permission.camera.status;
  }

  Future<PermissionStatus> microphoneStatus() {
    return Permission.microphone.status;
  }

  Future<Map<Permission, PermissionStatus>> requestVideoCallPermissions() {
    return [Permission.camera, Permission.microphone].request();
  }

  Future<PermissionStatus> mediaLibraryStatus() {
    return Permission.photos.status;
  }

  Future<PermissionStatus> requestMediaLibrary() {
    return Permission.photos.request();
  }
}
