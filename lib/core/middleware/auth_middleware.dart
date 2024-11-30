// lib/core/middleware/auth_middleware.dart

import 'package:poker_tracker/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthMiddleware {
  static String? handleRedirect(context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuth = user != null;

    final isAuthRoute = state.location == AppConstants.routeLogin ||
        state.location == AppConstants.routeRegister;

    // If not authenticated and trying to access protected route
    if (!isAuth && !isAuthRoute) {
      return AppConstants.routeLogin;
    }

    // If authenticated and trying to access auth routes
    if (isAuth && isAuthRoute) {
      return AppConstants.routeHome;
    }

    return null;
  }
}
