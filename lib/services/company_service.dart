import 'package:hive/hive.dart';
import '../models/company.dart';

class CompanyService {
  static const String _boxName = 'companies';
  late Box<Company> _companyBox;

  Future<void> init() async {
    _companyBox = await Hive.openBox<Company>(_boxName);
  }

  Future<void> addCompany(Company company) async {
    await _companyBox.add(company);
  }

  List<Company> getAllCompanies() {
    return _companyBox.values.toList();
  }

  Future<void> updateCompany(int index, Company company) async {
    await _companyBox.putAt(index, company);
  }

  Future<void> deleteCompany(int index) async {
    await _companyBox.deleteAt(index);
  }

  Company? getCurrentCompany() {
    final currentCompanyIndex = Hive.box<int>('settings').get('currentCompanyIndex');
    if (currentCompanyIndex != null && currentCompanyIndex < _companyBox.length) {
      return _companyBox.getAt(currentCompanyIndex);
    }
    return null;
  }

  Future<void> setCurrentCompany(int index) async {
    await Hive.box<int>('settings').put('currentCompanyIndex', index);
  }
} 