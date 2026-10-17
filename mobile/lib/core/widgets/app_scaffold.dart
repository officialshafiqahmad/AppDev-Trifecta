import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/theme_ext.dart';
import 'sync_indicator.dart';

/// The standard scaffold for all application screens.
/// Enforces safe area, content centering, max content width (640),
/// responsive padding, and the ALWAYS-VISIBLE sync status indicator.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.titleKey,
    this.titleWidget,
    this.titleStyle,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showSyncIndicator = true,
  });

  final Widget body;
  final String? titleKey;
  final Widget? titleWidget;
  final TextStyle? titleStyle;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showSyncIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final textStyles = context.text;
    final hasAppBar = titleKey != null || titleWidget != null || showSyncIndicator;

    final effectiveActions = <Widget>[
      if (actions != null) ...actions!,
      if (showSyncIndicator) const SyncIndicator(),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: !hasAppBar
          ? null
          : AppBar(
              backgroundColor: colors.background,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              toolbarHeight: sizes.appBar,
              centerTitle: false,
              leading: leading,
              title: titleWidget ??
                  (titleKey != null
                      ? Text(
                          titleKey!.tr,
                          style: titleStyle ?? textStyles.titleLg,
                        )
                      : null),
              actions: effectiveActions,
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = sizes.paddingFor(constraints.maxWidth);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: sizes.contentMaxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: body,
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
