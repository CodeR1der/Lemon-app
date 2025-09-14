import 'package:flutter/material.dart';

/// Универсальный виджет для добавления Pull to Refresh функциональности
class RefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enablePullDown;
  final bool enablePullUp;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;

  const RefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enablePullDown = true,
    this.enablePullUp = false,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).primaryColor,
      backgroundColor: backgroundColor ?? Colors.white,
      displacement: displacement,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}

/// Специализированный виджет для списков с Pull to Refresh
class RefreshableListView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final Color? color;
  final Color? backgroundColor;

  const RefreshableListView({
    super.key,
    required this.children,
    required this.onRefresh,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshWrapper(
      onRefresh: onRefresh,
      color: color,
      backgroundColor: backgroundColor,
      child: ListView(
        controller: controller,
        padding: padding,
        shrinkWrap: shrinkWrap,
        children: children,
      ),
    );
  }
}

/// Специализированный виджет для GridView с Pull to Refresh
class RefreshableGridView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final bool shrinkWrap;
  final Color? color;
  final Color? backgroundColor;

  const RefreshableGridView({
    super.key,
    required this.children,
    required this.onRefresh,
    this.controller,
    this.padding,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.shrinkWrap = false,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshWrapper(
      onRefresh: onRefresh,
      color: color,
      backgroundColor: backgroundColor,
      child: GridView.count(
        controller: controller,
        padding: padding,
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        shrinkWrap: shrinkWrap,
        children: children,
      ),
    );
  }
}

/// Специализированный виджет для SingleChildScrollView с Pull to Refresh
class RefreshableScrollView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final Color? color;
  final Color? backgroundColor;

  const RefreshableScrollView({
    super.key,
    required this.children,
    required this.onRefresh,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshWrapper(
      onRefresh: onRefresh,
      color: color,
      backgroundColor: backgroundColor,
      child: SingleChildScrollView(
        controller: controller,
        padding: padding,
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
