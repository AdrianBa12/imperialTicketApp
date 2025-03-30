import 'package:flutter/material.dart';
import 'package:imperialticketapp/screens/seat_selection_screen.dart';
import 'package:imperialticketapp/services/payment_service.dart';

import 'package:imperialticketapp/services/socket_service.dart';

import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';


import 'firebase_options.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/search_screen.dart';
import 'screens/bus_list_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/ticket_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/my_bookings_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('No se pudo inicializar Firebase: $e');
    // Continue with the app even if Firebase initialization fails
  }
  try {
    await PaymentService.initialize();
  } catch (e) {
    debugPrint('No se pudo inicializar Stripe: $e');
    // Continue with the app even if Stripe initialization fails
  }

  // Initialize socket connection
  SocketService.initSocket();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => BookingProvider()),
        Provider(create: (context) => PaymentService()),

      ],
      child: MaterialApp(
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
          '/splash': (context) => const SplashScreen(),
          '/': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/search': (context) => const SearchScreen(),
          '/bus-list': (context) => const BusListScreen(),
          '/seat_selected': (context) => const SeatSelectionScreen(),
          '/booking': (context) => const BookingScreen(),
          '/payment': (context) => const PaymentScreen(),
          '/ticket': (context) => const TicketScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/my-bookings': (context) => const MyBookingsScreen(),
        },
      ),
    );
  }
}