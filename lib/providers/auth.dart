import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryData;
  String _userId;
  Timer _AuthTimer;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expiryData != null &&
        _expiryData.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyDt1m6Vm35wBuo2bDAH5HAMjdeOso_3RMI';
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final responseDate = json.decode(response.body);
      if (responseDate['error'] != null) {
        throw HttpException(responseDate['error']['message']);
      }
      _token = responseDate['idToken'];
      _userId = responseDate['localId'];
      _expiryData = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseDate['expiresIn'],
          ),
        ),
      );
      autoLogout();
      notifyListeners();
    } catch (error) {
      throw error;
    }

    // print(json.decode(response.body));
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  void logout() {
    _token = null;
    _userId = null;
    _expiryData = null;
    if (_AuthTimer != null) {
      _AuthTimer.cancel();
      _AuthTimer = null;
    }
    notifyListeners();
  }

  void autoLogout() {
    if (_AuthTimer != null) {
      _AuthTimer.cancel();
    }
    final timeToExpiry = _expiryData.difference(DateTime.now()).inSeconds;
    _AuthTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }
}
