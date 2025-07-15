import 'package:flutter/material.dart';
import '../models/company.dart';

class CompanyContext extends ChangeNotifier {
  Company? _selectedCompany;

  Company? get selectedCompany => _selectedCompany;

  void setCompany(Company company) {
    _selectedCompany = company;
    notifyListeners();
  }

  void clearCompany() {
    _selectedCompany = null;
    notifyListeners();
  }
} 