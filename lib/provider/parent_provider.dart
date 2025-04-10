import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateProvider for storing parent email
final parentEmailProvider = StateProvider<String?>((ref) => null);

final parentNameProvider = StateProvider<String?>((ref)=>null);

final connectedChildsProvider = StateProvider<List<dynamic?>>((ref) => []);

