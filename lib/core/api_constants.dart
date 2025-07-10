class ApiConstants {
  // Home
  //static const String baseUrl = "http://192.168.100.14:5000/api";

  //University
  static const String baseUrl = "https://childcompass-backend-z0nv.onrender.com/api";
  static const String port ='5000';


  //***************************Web Sockets********************************
   static const String ActiveStatusSharingSocket ='ws://childcompass-backend-z0nv.onrender.com/activeStatus';
   static const String locationSharingSocket ='ws://childcompass-backend-z0nv.onrender.com/location';
   // static const String locationSharingSocket ='ws://192.168.100.14:5000/location';
   // static const String ActiveStatusSharingSocket ='ws://192.168.100.14:5000/activeStatus';



  // *********************Child EndPoints***********************************

  static const String childRegisteration = "$baseUrl/child/register";
  static const String childNamesByConnection = "$baseUrl/child/names-by-connection";
  static const String logAppUseage = "$baseUrl/child/logAppUsage";
  static const String addGeofence = "$baseUrl/child/addGeofence";
  static const String getGeofence = "$baseUrl/child/geofenceLocations";
  static const String removeGeofence = "$baseUrl/child/remove-geofence";
  static const String logLocationHistory = "$baseUrl/child/logLocationHistory";
  static const String getLocationHistory = "$baseUrl/child/locationHistory";
  static const String sosAlert ="$baseUrl/child/sosAlert";
  static const String setSpeedLimit ="$baseUrl/child/setSpeedLimit";
  static const String deleteAccount ="$baseUrl/child/deleteAccount";



  // *********************Parent EndPoints***********************************

  static const String parentRegister = "$baseUrl/parent/register";
  static const String emailVerification = "$baseUrl/parent/verify-email";
  static const String parentLogin = "$baseUrl/parent/login";
  static const String connectChild = "$baseUrl/parent/add-child";
  static const String parentDetails= "$baseUrl/parent/parent-details";
  static const String removeChild= "$baseUrl/parent/remove-child";
  static const String parentsList = "$baseUrl/parent/parents-by-connection/";
  static const String parentNotificationSettings = "$baseUrl/parent/update-notification-settings";
  static const String forgotPassword = "$baseUrl/parent/forgot-password";
  static const String resetPassword = "$baseUrl/parent/reset-password";
  static const String changePassword = "$baseUrl/parent/change-password";
  static const String changeEmail = "$baseUrl/parent/change-email";
  static const String verifyEmailChange = "$baseUrl/parent//verify-email-change";

   // *********************Task EndPoints***********************************

   static const String addTask = "$baseUrl/task/add";
   static const String fetchTask="$baseUrl/task/task?connectionString=";
   static const String completeTask="$baseUrl/task/";
   static const String fetchTaskParent="$baseUrl/task/";

   //*********************Messaging EndPoints******************************

   static const String messaging = "$baseUrl/message/";

}
