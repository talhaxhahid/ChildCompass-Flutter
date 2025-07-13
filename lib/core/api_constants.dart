class ApiConstants {

  //static const String serverUrl="childcompass-backend-z0nv.onrender.com";
  static const String serverUrl = "childcompass-backend-production.up.railway.app";

  //University
  static const String baseUrl = "https://$serverUrl/api";
  static const String port ='5000';


  //***************************Web Sockets********************************
   static const String ActiveStatusSharingSocket ='wss://$serverUrl/activeStatus';
   static const String locationSharingSocket ='wss://$serverUrl/location';
  static const String sosAlertSocket ='wss://$serverUrl/sosAlert';




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
  static const String permissionIssue ="$baseUrl/child/permissionIssue";



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
