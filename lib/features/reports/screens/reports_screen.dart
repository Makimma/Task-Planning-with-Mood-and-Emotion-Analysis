import 'package:flutter/material.dart';
import 'package:flutter_appp/features/reports/widgets/overview_report.dart';
import 'package:flutter_appp/features/reports/widgets/mood_report.dart';
import 'package:flutter_appp/features/reports/data/reports_data_provider.dart';
import '../../../core/widgets/period_selector.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with AutomaticKeepAliveClientMixin {
  String selectedPeriod = "Неделя";
  final ReportsDataProvider _dataProvider = ReportsDataProvider();
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      await _dataProvider.initialize(selectedPeriod);
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _dataProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Отчеты",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          titleSpacing: 16,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: PeriodSelector(
                  selectedPeriod: selectedPeriod,
                  onPeriodChanged: (value) {
                    setState(() {
                      selectedPeriod = value;
                    });
                    _initializeData();
                  },
                ),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment, size: 18),
                    SizedBox(width: 8),
                    Text('Обзор'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 18),
                    SizedBox(width: 8),
                    Text('Графики'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewReport(
              dataProvider: _dataProvider,
              selectedPeriod: selectedPeriod,
              isLoading: isLoading,
            ),
            MoodReport(
              dataProvider: _dataProvider,
              selectedPeriod: selectedPeriod,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
} 