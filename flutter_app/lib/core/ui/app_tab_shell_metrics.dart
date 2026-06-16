import 'package:flutter/material.dart';

class AppTabShellMetrics {
  const AppTabShellMetrics._(this._layoutScale);

  factory AppTabShellMetrics.of(BuildContext context) {
    final rawScale = MediaQuery.textScalerOf(context).scale(1);
    final layoutScale = rawScale.clamp(0.92, 1.08).toDouble();
    return AppTabShellMetrics._(layoutScale);
  }

  static const double headerAvatarSize = 48;
  static const double headerSpacing = 12;
  static const double headerBlockHeight = 76;
  static const double headerLabelFontSize = 15;
  static const double headerTitleFontSize = 21;
  static const double actionButtonSize = 48;
  static const double actionIconSize = 24;
  static const double sectionTitleFontSize = 21;
  static const double cardTitleFontSize = 17;
  static const double bodyFontSize = 14;
  static const double metaFontSize = 13;
  static const double floatingTabBarHeight = 86;
  static const double floatingTabBarTopSpacing = 8;
  static const double floatingTabBarBottomSpacing = 12;

  final double _layoutScale;

  double size(double base) => base * _layoutScale;

  double radius(double base) => size(base);

  EdgeInsets edgeInsets(double left, double top, double right, double bottom) {
    return EdgeInsets.fromLTRB(
      size(left),
      size(top),
      size(right),
      size(bottom),
    );
  }

  EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: size(horizontal),
      vertical: size(vertical),
    );
  }

  double floatingTabBarInset(BuildContext context, {double extraSpacing = 0}) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return size(
          floatingTabBarHeight +
              floatingTabBarTopSpacing +
              floatingTabBarBottomSpacing +
              extraSpacing,
        ) +
        safeBottom;
  }
}
