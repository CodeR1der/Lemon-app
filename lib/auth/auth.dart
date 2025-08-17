import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/user_service.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget homeScreen;
  final SupabaseClient supabase;

  const AuthWrapper(
      {required this.homeScreen, required this.supabase, super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final userService = UserService.to;
      if (widget.supabase.auth.currentSession != null &&
          !userService.isInitialized.value) {
        await userService
            .initializeUser(widget.supabase.auth.currentSession!.user.id);
      }
    } catch (error) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final userService = UserService.to;
      if (!userService.isInitialized.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return userService.isLoggedIn.value
          ? widget.homeScreen
          : AuthScreen(supabase: widget.supabase);
    });
  }
}