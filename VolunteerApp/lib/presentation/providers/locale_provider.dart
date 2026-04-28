import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('vi', 'VN');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggleLocale() {
    if (_locale.languageCode == 'vi') {
      _locale = const Locale('en', 'US');
    } else {
      _locale = const Locale('vi', 'VN');
    }
    notifyListeners();
  }

  String get currentLanguageName {
    return _locale.languageCode == 'vi' ? 'Tiếng Việt' : 'English';
  }
}
