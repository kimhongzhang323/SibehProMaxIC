import 'package:flutter/material.dart';

class QuickActionItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String routeName;
  final String? assetPath;
  final Map<String, dynamic>? arguments;

  const QuickActionItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.routeName,
    this.assetPath,
    this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'iconCode': icon.codePoint,
        'colorValue': color.value,
        'routeName': routeName,
        'assetPath': assetPath,
        'arguments': arguments,
      };

  factory QuickActionItem.fromJson(Map<String, dynamic> json) => QuickActionItem(
        id: json['id'],
        label: json['label'],
        icon: IconData(json['iconCode'], fontFamily: 'MaterialIcons'),
        color: Color(json['colorValue']),
        routeName: json['routeName'],
        assetPath: json['assetPath'],
        arguments: json['arguments'],
      );
}
