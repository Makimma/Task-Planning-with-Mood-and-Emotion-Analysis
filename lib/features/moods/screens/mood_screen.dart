import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/mood_viewmodel.dart';
import '../widgets/mood_selector.dart';
import '../widgets/gradient_mood_icon.dart';
import '../widgets/mood_history.dart';

final GlobalKey<MoodHistoryState> moodHistoryKey = GlobalKey<MoodHistoryState>();

class MoodScreen extends StatelessWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ChangeNotifierProvider(
          create: (_) => MoodViewModel(prefs: snap.data!),
          child: _MoodScreenContent(),
        );
      },
    );
  }
}

class _MoodScreenContent extends StatefulWidget {
  @override
  __MoodScreenContentState createState() => __MoodScreenContentState();
}

class __MoodScreenContentState extends State<_MoodScreenContent>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _noteController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodViewModel>().init();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Настроение',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: RefreshIndicator(
          onRefresh: () => context.read<MoodViewModel>().init(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<MoodViewModel>(builder: (_, vm, __) {
                    if (vm.state == MoodState.loading) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final moodText = vm.currentMood?.type.isNotEmpty == true
                        ? vm.currentMood!.type
                        : 'Настроение не выбрано';
                    return Container(
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
                      child: Row(
                        children: [
                          GradientMoodIcon(
                            mood: vm.currentMood?.type ?? '',
                            size: 40,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              moodText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 24),

                  Selector<MoodViewModel, String>(
                    selector: (_, vm) => vm.selectedType,
                    builder: (_, selected, __) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Выберите ваше настроение',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 12),
                        MoodSelector(
                          selectedMood: selected,
                          onMoodSelected: context
                              .read<MoodViewModel>()
                              .selectMood,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  Text(
                    'Текстовая заметка',
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
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 3,
                      onChanged: context.read<MoodViewModel>().setNote,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                        hintText:
                        'Опишите, что повлияло на ваше настроение...',
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final vm = context.read<MoodViewModel>();
                        await vm.saveMood();
                        _noteController.clear();
                        if (vm.state == MoodState.error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      vm.errorMessage ?? 'Произошла ошибка',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Color(0xFFB71C1C)
                                  : Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: EdgeInsets.all(8),
                              duration: Duration(seconds: 4),
                              action: SnackBarAction(
                                label: 'OK',
                                textColor: Colors.white,
                                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Настроение сохранено',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Color(0xFF1B5E20)
                                  : Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: EdgeInsets.all(8),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          moodHistoryKey.currentState?.loadOfflineMoods();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Сохранить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'История настроений',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  MoodHistory(key: moodHistoryKey, isOnline: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
