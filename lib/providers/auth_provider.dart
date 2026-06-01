import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/student_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StudentModel? _currentStudent;
  bool _isLoading = false;
  bool _initialCheckDone = false;
  StreamSubscription? _authSubscription;

  StudentModel? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  bool get initialCheckDone => _initialCheckDone;
  bool get isAuthenticated => _currentStudent != null;

  AuthProvider() {
    // Safety Timeout: Force show login if database is too slow (e.g. 5 seconds)
    Future.delayed(const Duration(seconds: 5), () {
      if (!_initialCheckDone) {
        _initialCheckDone = true;
        notifyListeners();
      }
    });

    _authSubscription = _authService.userState.listen((User? user) async {
      if (user != null) {
        try {
          await fetchStudentData(user.email!);
        } catch (e) {
          _currentStudent = null;
        }
      } else {
        _currentStudent = null;
      }
      _initialCheckDone = true;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.login(email, password);
      bool success = await fetchStudentData(email);
      
      if (!success) {
        await logout();
        throw Exception("Access Denied: You are not registered as a student.");
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchStudentData(String email) async {
    try {
      final student = await _authService.getStudentData(email);
      if (student != null) {
        _currentStudent = student;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error fetching student: $e");
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentStudent = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
