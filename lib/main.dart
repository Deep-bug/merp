import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/merp_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await AppDependencies.bootstrap();

  runApp(MerpApp(dependencies: dependencies));
}
