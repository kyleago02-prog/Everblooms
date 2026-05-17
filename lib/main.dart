// lib/main.dart
import 'package:everbloom/providers/seller_provider.dart';
import 'package:everbloom/screens/order/orders_screen.dart';
import 'package:everbloom/screens/seller/seller_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/search_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'package:everbloom/screens/profile/profile_screen.dart';

import 'package:everbloom/theme/app_theme.dart';

// Home wrapper to handle conditional navigation
class HomeWrapper extends StatelessWidget {
  const HomeWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Print for debugging
    debugPrint('HomeWrapper - User type: ${authProvider.currentUser?.userType}');
    debugPrint('HomeWrapper - Is seller: ${authProvider.isSeller}');

    // Return the appropriate home screen based on user type
    if (authProvider.isAuthenticated && authProvider.isSeller) {
      debugPrint('➡️ Redirecting to SELLER home');
      return const SellerHomeScreen();
    } else {
      debugPrint('➡️ Redirecting to BUYER home');
      return const HomeScreen();
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => SellerProvider()),
      ],
      child: MaterialApp(
        title: 'Everbloom',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeWrapper(),
          '/seller-home': (context) => const SellerHomeScreen(), // Direct route for seller home
          '/search': (context) => const SearchScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}