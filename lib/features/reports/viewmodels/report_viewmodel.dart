import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_appp/core/di/service_locator.dart';
import 'package:flutter_appp/features/reports/models/report_model.dart';
import 'package:flutter_appp/features/reports/services/report_service.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportService _service = sl<ReportService>();
  ReportModel? _reportData;
  String _selectedPeriod = "Неделя";
  StreamSubscription? _dataChangedSubscription;

  ReportModel? get reportData => _reportData;
  bool get isLoading => false;
  String get selectedPeriod => _selectedPeriod;
  String? get error => null;

  Future<void> initialize(String period) async {
    _selectedPeriod = period;
    _service.setPeriod(period, force: true);
    _dataChangedSubscription?.cancel();
    _dataChangedSubscription = _service.onDataChanged.listen((_) {
      _reportData = _service.getCachedReport();
      notifyListeners();
    });
    _reportData = _service.getCachedReport();
    notifyListeners();
  }

  void changePeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      _service.setPeriod(period);
    }
  }

  @override
  void dispose() {
    _dataChangedSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
} 