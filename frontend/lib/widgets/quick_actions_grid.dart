import 'package:flutter/material.dart';
import '../models/quick_action_item.dart';

class QuickActionsGrid extends StatefulWidget {
  final List<QuickActionItem> items;
  final Function(List<QuickActionItem>) onReorder;
  final Function(QuickActionItem) onTap;
  final VoidCallback onAddPressed;

  const QuickActionsGrid({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  State<QuickActionsGrid> createState() => _QuickActionsGridState();
}

class _QuickActionsGridState extends State<QuickActionsGrid> with SingleTickerProviderStateMixin {
  bool _isEditMode = false;
  late List<QuickActionItem> _localItems;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      } else if (status == AnimationStatus.dismissed && _isEditMode) {
        _shakeController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(QuickActionsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _localItems = List.from(widget.items);
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _shakeController.forward();
      } else {
        _shakeController.stop();
        _shakeController.reset();
        widget.onReorder(_localItems); // Save order on exit
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: _toggleEditMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isEditMode ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isEditMode ? 'Done' : 'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isEditMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox( // Constrain height mainly for stability, but ReorderableListView needs space
          height: 100, 
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _localItems.length + (_isEditMode ? 1 : 0),
            proxyDecorator: (child, index, animation) {
               return Material(
                 color: Colors.transparent,
                 elevation: 6,
                 shadowColor: Colors.black26,
                 child: child,
               );
            },
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              // Prevent reordering the "Add" button
              if (newIndex >= _localItems.length) return;
              
              setState(() {
                final QuickActionItem item = _localItems.removeAt(oldIndex);
                _localItems.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              if (index == _localItems.length) {
                // Add Button Placeholder
                return Container(
                  key: const ValueKey('add_button'),
                  margin: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: widget.onAddPressed,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                          ),
                          child: const Icon(Icons.add, color: Colors.black54, size: 26),
                        ),
                        const SizedBox(height: 8),
                        const Material(
                          type: MaterialType.transparency,
                          child: Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final item = _localItems[index];

              return ReorderableDragStartListener(
                key: ValueKey(item.id),
                index: index,
                enabled: _isEditMode, // Only allow dragging in edit mode
                child: AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final offset = _isEditMode
                        ? (index % 2 == 0 ? 1.0 : -1.0) * _shakeController.value * 2
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      child: GestureDetector(
                        onTap: _isEditMode ? null : () => widget.onTap(item),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: item.color.withAlpha(25), // Use withAlpha for simple opacity
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: item.assetPath != null
                                      ? Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Image.asset(item.assetPath!, fit: BoxFit.contain),
                                        )
                                      : Icon(item.icon, color: item.color, size: 26),
                                ),
                                const SizedBox(height: 8),
                                Material(
                                  type: MaterialType.transparency,
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isEditMode)
                              Positioned(
                                top: -6,
                                left: -6,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _localItems.removeAt(index);
                                    });
                                    // Update parent immediately or on Done? 
                                    // For simplicity updating parent immediately for removals might be safer or wait till done
                                    widget.onReorder(_localItems); 
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.remove_circle, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

      ],
    );
  }
}
