import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';
import 'screens/user/user_scanner_screen.dart';
import 'screens/admin/admin_view.dart';
import 'screens/admin/admin_report_chart_screen.dart';
import 'screens/admin/admin_report_screen.dart';
import 'screens/admin/alarm_details_screen.dart';
import 'screens/user/user_alarm_details_screen.dart';
import 'services/auth_service.dart';
import 'viewmodels/login_viewmodel.dart';
import 'config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginViewModel>(
          create: (_) => LoginViewModel(
            authService: AuthService(baseUrl: Config.apiBaseUrl),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Sistema de Autenticación',
        home: const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminView(),
          '/user': (context) => const UserScannerScreen(),
          '/admin/report_chart': (context) => const AdminReportChartScreen(),
          '/admin/report_general': (context) => const AdminReportScreen(),
          '/admin/alarm_details': (context) => const AlarmDetailsScreen(),
          '/user/alarm_details': (context) => const UserAlarmDetailsScreen(),
        },
      ),
    );
  }
}
