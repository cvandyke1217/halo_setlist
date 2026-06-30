import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'models/repository.dart';
import 'screens/setlist_list_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: [${record.loggerName}] ${record.time}: ${record.message}');
  });

  runApp(const HaloSetlistApp());
}

class HaloSetlistApp extends StatelessWidget {
  const HaloSetlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Halo Setlist',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final SetlistRepository _repo = SetlistRepository();
  late final Future<void> _loaded;

  @override
  void initState() {
    super.initState();
    _loaded = _repo.load().then((_) {
      ThemeController.mode.value = ThemeController.fromName(_repo.themeModeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loaded,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return SetlistListScreen(repo: _repo);
      },
    );
  }
}
