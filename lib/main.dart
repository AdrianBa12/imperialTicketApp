import 'package:flutter/material.dart';
import 'package:imperialticketapp/providers/ticket_provider.dart';
import 'package:imperialticketapp/screens/passenger_info_screen.dart';
import 'package:imperialticketapp/screens/payments_screen.dart';
import 'package:imperialticketapp/screens/seat_selection_screen.dart';
import 'package:imperialticketapp/services/payment_service.dart';
import 'package:imperialticketapp/screens/search_screens.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/bus_list_screen.dart';
import 'screens/booking_screens.dart';

import 'screens/ticket_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/my_bookings_screen.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', 'ES'); 
  runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => TicketProvider()),
      ChangeNotifierProvider(create: (context) => AuthProvider()),
      ChangeNotifierProvider(create: (context) => BookingProvider()),
      Provider(create: (context) => PaymentService()),
    ],
    child: const MyApp(),
  ),
);
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
        title: 'TurismoImperial',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.lime,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F0F10),
            primary: const Color(0xFFBF303C),
            secondary: const Color(0xFFF2A516),
            surface: Colors.white,
          ),
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFBF303C),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBF303C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        initialRoute: '/splash',
        
        routes: {
          
          // '/search': (context) =>const RouteSelectionScreen(),
          '/search': (context) => const SearchScreen(),      
          // '/bus-selection': (context) =>  BusSelectionScreen(),
          '/seat-selection': (context) => const SeatSelectionScreen(),
          '/passenger-info': (context) =>  PassengerInfoScreen(),
          '/payments': (context) => const PaymentScreen(),
          
          
          '/splash': (context) => const SplashScreen(),
          '/': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          
          '/bus-list': (context) => const BusListScreen(),
          
          '/booking': (context) => const BookingScreen(scheduleId: '',),
          
          '/ticket': (context) => const TicketScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/my-bookings': (context) => const MyBookingsScreen(),
        },
      );
  }
}