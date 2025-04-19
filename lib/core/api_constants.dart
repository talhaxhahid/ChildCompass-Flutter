class ApiConstants {
  // Home
   static const String baseUrl = "http://192.168.100.14:5000/api";
  //University
  //static const String baseUrl = "https://childcompass-backend.onrender.com/api";
  static const String port ='5000';


  //***************************Web Sockets********************************
   //static const String ActiveStatusSharingSocket ='ws://childcompass-backend.onrender.com/activeStatus';
   //static const String locationSharingSocket ='ws://childcompass-backend.onrender.com/location';
   static const String locationSharingSocket ='ws://192.168.100.14:5000/location';
   static const String ActiveStatusSharingSocket ='ws://192.168.100.14:5000/activeStatus';


  // *********************Child EndPoints***********************************

  static const String childRegisteration = "$baseUrl/child/register";
  static const String childNamesByConnection = "$baseUrl/child/names-by-connection";



  // *********************Parent EndPoints***********************************

  static const String parentRegister = "$baseUrl/parent/register";
  static const String emailVerification = "$baseUrl/parent/verify-email";
  static const String parentLogin = "$baseUrl/parent/login";
  static const String connectChild = "$baseUrl/parent/add-child";
  static const String parentDetails= "$baseUrl/parent/parent-details";
  static const String removeChild= "$baseUrl/parent/remove-child";
  static const String parentsList = "$baseUrl/parent/parents-by-connection/";

}
