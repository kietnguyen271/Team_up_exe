import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/ocean/ocean_host.dart';
import 'ocean_gallery_screen.dart';
import 'ui_gallery_screen.dart';

class UiPrototypeApp extends StatelessWidget {
  const UiPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => MotionScope(
          settings: Motion.settings,
          child: OceanHost(child: child ?? const SizedBox.shrink()),
        ),
        routes: {
          '/ui-gallery/ocean': (_) => const OceanGalleryScreen(),
        },
        home: const UiGalleryScreen(),
      );
}
