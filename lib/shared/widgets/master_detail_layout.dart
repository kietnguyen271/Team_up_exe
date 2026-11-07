import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class MasterDetailLayout extends StatelessWidget {
  const MasterDetailLayout({
    super.key,
    required this.master,
    required this.detail,
  });

  final Widget master;
  final Widget detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSizes.desktopBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              master,
              const SizedBox(height: AppSpacing.s24),
              detail,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: constraints.maxWidth * AppSizes.masterShare,
              child: master,
            ),
            const SizedBox(width: AppSpacing.s24),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}
