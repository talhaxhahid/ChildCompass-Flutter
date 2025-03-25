import 'package:permission_handler/permission_handler.dart';

class permissions {

 static Future<void> requestLocationPermissions() async {
    // Request foreground location permission
    var status = await Permission.location.request();
    if (status.isGranted) {
      // Request background location permission after foreground is granted
      var bgStatus = await Permission.locationAlways.request();
      if (bgStatus.isGranted) {
        print('Background location permission granted');
      } else {
        print('Background location permission denied');
      }
    } else {
      print('Foreground location permission denied');
    }
  }


}