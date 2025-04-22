import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateProvider for storing parent email
final parentEmailProvider = StateProvider<String?>((ref) => null);

final parentNameProvider = StateProvider<String?>((ref)=>null);

final connectedChildsProvider = StateProvider<List<dynamic>?>((ref) => []);

final connectedChildsStatusProvider = StateProvider<Map<dynamic,dynamic>?>((ref) => {});

final connectedChildsNameProvider = StateProvider<Map<dynamic,dynamic>?>((ref) => {});

final connectedChildsImageProvider = StateProvider<Map<dynamic,dynamic>?>((ref) => {});

final currentChildProvider= StateProvider<String?>((ref) => null);

final speedProvider = StateProvider<String?>((ref) => "0");

final batteryProvider = StateProvider<String?>((ref) => "0");

final maxSpeedProvider = StateProvider<String?>((ref) => "0");




