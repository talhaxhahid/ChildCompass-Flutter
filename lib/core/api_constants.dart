class ApiConstants {
  // static const String baseUrl = "https://childcompass-backend.onrender.com/api";
  static const String baseUrl = "http://192.168.100.14:5000/api";
  static const String port ='5000';


  //***************************Web Sockets********************************

  // static const String locationSharingSocket ='ws://childcompass-backend.onrender.com/location:5000';
  static const String locationSharingSocket ='ws://192.168.100.14:5000/location';


  // *********************Child EndPoints***********************************

  static const String childRegisteration = "$baseUrl/child/register";



  // *********************Parent EndPoints***********************************

  static const String parentRegister = "$baseUrl/parent/register";
  static const String emailVerification = "$baseUrl/parent/verify-email";
  static const String parentLogin = "$baseUrl/parent/login";
  static const String connectChild = "$baseUrl/parent/add-child";
  static const String parentDetails= "$baseUrl/parent/parent-details";

}
