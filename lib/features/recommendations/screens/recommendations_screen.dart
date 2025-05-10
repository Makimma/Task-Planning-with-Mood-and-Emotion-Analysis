import 'package:flutter/material.dart';
import 'package:flutter_appp/features/tasks/services/task_actions.dart';
import 'package:flutter_appp/features/tasks/widgets/task_card.dart';
import 'package:provider/provider.dart';
import '../viewmodels/recommendation_viewmodel.dart';
import '../../moods/widgets/gradient_mood_icon.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecommendationViewModel(),
      child: _RecommendationsScreenContent(),
    );
  }
}

class _RecommendationsScreenContent extends StatefulWidget {
  @override
  _RecommendationsScreenContentState createState() =>
      _RecommendationsScreenContentState();
}

class _RecommendationsScreenContentState
    extends State<_RecommendationsScreenContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Рекомендации',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<RecommendationViewModel>().init(),
        child: Consumer<RecommendationViewModel>(
          builder: (context, viewModel, child) {
            if (!viewModel.isInitialized) {
              return Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${viewModel.error}'),
                    ElevatedButton(
                      onPressed: () => viewModel.init(),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.currentMood == null)
                    Card(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red.shade900.withOpacity(0.2)
                          : Colors.red.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Укажите ваше настроение, чтобы получать более точные рекомендации.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (viewModel.currentMood != null) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Текущее настроение",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              GradientMoodIcon(
                                mood: viewModel.currentMood!,
                                size: 40,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  viewModel.currentMood!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                  Text(
                    "Рекомендуемые задачи",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(child: _buildTaskList(viewModel)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskList(RecommendationViewModel viewModel) {
    if (viewModel.recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Нет активных задач",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16),
      itemCount: viewModel.recommendations.length,
      itemBuilder: (context, index) {
        final task = viewModel.recommendations[index];

        return Dismissible(
          key: Key(task['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_forever,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Удалить',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await TaskActions.showDeleteConfirmation(
                context, task['id']);
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TaskCard(
              task: task,
              isCompleted: false,
              onEdit: () => TaskActions.showEditTaskDialog(context, task),
              onComplete: () => TaskActions.completeTask(task['id'], context),
            ),
          ),
        );
      },
    );
  }
}
