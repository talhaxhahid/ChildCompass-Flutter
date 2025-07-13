import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';

class permissions {

 static Future<bool> grantRequiredPermissions() async {
     final location_permission = await requestLocationPermissions() ;
     final useage_permission = await requestUseagePermissions() ;

     return location_permission && useage_permission;
 }

 static Future<bool> requestLocationPermissions() async {
    // Request foreground location permission
    var status = await Permission.location.request();
    if (status.isGranted) {
      // Request background location permission after foreground is granted
      var bgStatus = await Permission.locationAlways.request();
      if (bgStatus.isGranted) {
        print('Background location permission granted');
        return true;
      } else {
        print('Background location permission denied');
        return false;
      }
    } else {
      print('Foreground location permission denied');
      return false;
    }
  }

  static Future<bool> requestUseagePermissions() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.get('user');
    if(user=='parent'){
      return true;
    }
    bool hasPermission = await UsageStats.checkUsagePermission() ?? false;
    if (!hasPermission) {
      await UsageStats.grantUsagePermission();
    }
    else{
      return true;
    }

     hasPermission = await UsageStats.checkUsagePermission() ?? false;
    return hasPermission;


  }


}