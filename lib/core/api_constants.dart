class ApiConstants {
  // Home
  //  static const String baseUrl = "http://10.135.49.203:5002/api";

  //University
  static const String baseUrl = "https://childcompass-backend-z0nv.onrender.com/api";
  static const String port ='5000';


  //***************************Web Sockets********************************
   static const String ActiveStatusSharingSocket ='ws://childcompass-backend-z0nv.onrender.com/activeStatus';
   static const String locationSharingSocket ='ws://childcompass-backend-z0nv.onrender.com/location';
   // static const String locationSharingSocket ='ws://10.135.49.203:5002/location';
   // static const String ActiveStatusSharingSocket ='ws://10.135.49.203:5002/activeStatus';



  // *********************Child EndPoints***********************************

  static const String childRegisteration = "$baseUrl/child/register";
  static const String childNamesByConnection = "$baseUrl/child/names-by-connection";
  static const String logAppUseage = "$baseUrl/child/logAppUsage";
  static const String addGeofence = "$baseUrl/child/addGeofence";
  static const String getGeofence = "$baseUrl/child/geofenceLocations";
  static const String removeGeofence = "$baseUrl/child/remove-geofence";



  // *********************Parent EndPoints***********************************

  static const String parentRegister = "$baseUrl/parent/register";
  static const String emailVerification = "$baseUrl/parent/verify-email";
  static const String parentLogin = "$baseUrl/parent/login";
  static const String connectChild = "$baseUrl/parent/add-child";
  static const String parentDetails= "$baseUrl/parent/parent-details";
  static const String removeChild= "$baseUrl/parent/remove-child";
  static const String parentsList = "$baseUrl/parent/parents-by-connection/";

   // *********************Task EndPoints***********************************

   static const String addTask = "$baseUrl/task/add";
   static const String fetchTask="$baseUrl/task/task?connectionString=";
   static const String completeTask="$baseUrl/task/";
   static const String fetchTaskParent="$baseUrl/task/";

   //*********************Messaging EndPoints******************************

   static const String messaging = "$baseUrl/message/";

}
