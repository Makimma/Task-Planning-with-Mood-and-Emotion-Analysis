import 'package:flutter/material.dart';

class SortSelector extends StatefulWidget {
  final String selectedOption;
  final Function(String) onOptionSelected;

  const SortSelector({
    required this.selectedOption,
    required this.onOptionSelected,
    Key? key,
  }) : super(key: key);

  @override
  _SortSelectorState createState() => _SortSelectorState();
}

class _SortSelectorState extends State<SortSelector> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;

  final Map<String, IconData> _sortIcons = {
    "Дата создания": Icons.access_time_rounded,
    "Дедлайн": Icons.calendar_today_rounded,
    "Приоритет": Icons.priority_high_rounded,
    "Эмоциональная нагрузка": Icons.psychology_rounded,
  };

  final List<Map<String, dynamic>> _options = [
    {"icon": Icons.access_time_rounded, "label": "Дата создания"},
    {"icon": Icons.calendar_today_rounded, "label": "Дедлайн"},
    {"icon": Icons.priority_high_rounded, "label": "Приоритет"},
    {"icon": Icons.psychology_rounded, "label": "Эмоциональная нагрузка"},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.addListener(() {
      if (_overlayEntry != null) {
        _overlayEntry!.markNeedsBuild();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _showOverlay();
        _controller.forward();
      } else {
        _controller.reverse().then((_) {
          _removeOverlay();
        });
      }
    });
  }

  void _showOverlay() {
    final RenderBox buttonBox = context.findRenderObject() as RenderBox;
    final Offset buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: buttonPosition.dy + buttonSize.height + 8,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.topRight,
              child: Container(
                width: 200,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 32,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _options.asMap().entries.map((entry) {
                    final option = entry.value;
                    final index = entry.key;
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final itemAnimation = Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            index * 0.1,
                            index * 0.1 + 0.6,
                            curve: Curves.easeOutCubic,
                          ),
                        ));

                        return FadeTransition(
                          opacity: itemAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0.2, 0),
                              end: Offset.zero,
                            ).animate(itemAnimation),
                            child: child!,
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () {
                          widget.onOptionSelected(option["label"]);
                          _toggleExpanded();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                option["icon"],
                                size: 20,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option["label"],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.selectedOption == option["label"])
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                _sortIcons[widget.selectedOption] ?? Icons.sort_rounded,
                key: ValueKey<String>(widget.selectedOption),
                size: 22,
                color: _isExpanded 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            AnimatedSize(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: _isExpanded ? null : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      opacity: _isExpanded ? 1.0 : 0.0,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          widget.selectedOption,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 