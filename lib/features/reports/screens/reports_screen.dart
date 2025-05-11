import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_appp/features/reports/widgets/overview_report.dart';
import 'package:flutter_appp/features/reports/widgets/mood_report.dart';
import 'package:flutter_appp/features/reports/viewmodels/report_viewmodel.dart';
import '../../../core/widgets/period_selector.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().initialize("Неделя");
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ReportViewModel>(
      builder: (context, viewModel, child) {
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
                      selectedPeriod: viewModel.selectedPeriod,
                      onPeriodChanged: viewModel.changePeriod,
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
                  reportData: viewModel.reportData,
                  selectedPeriod: viewModel.selectedPeriod,
                  isLoading: viewModel.isLoading,
            ),
            MoodReport(
                  reportData: viewModel.reportData,
                  selectedPeriod: viewModel.selectedPeriod,
                  isLoading: viewModel.isLoading,
            ),
          ],
        ),
      ),
        );
      },
    );
  }
} 