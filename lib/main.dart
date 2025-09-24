import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dfu_screen.dart';
import 'presentation/providers/ble_provider.dart';
import 'presentation/providers/dfu_provider.dart';
import 'core/constants/app_constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BleProvider()),
        ChangeNotifierProvider(create: (context) => DfuProvider()),
        ChangeNotifierProvider(create: (context) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const DfuScreen(),
      ),
    );
  }
}
