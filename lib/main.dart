// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/datasources/api_datasource.dart';
import 'presentation/blocs/health_bloc.dart';
import 'presentation/blocs/camera_list_bloc.dart';
import 'presentation/blocs/other_blocs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — change to landscape if needed for tablets
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FireWatchApp());
}

class FireWatchApp extends StatelessWidget {
  const FireWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Single ApiDataSource instance shared across all BLoCs
    final apiDataSource = ApiDataSource();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiDataSource>.value(value: apiDataSource),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HealthBloc>(
            create: (_) => HealthBloc(api: apiDataSource),
          ),
          BlocProvider<CameraListBloc>(
            create: (_) => CameraListBloc(api: apiDataSource),
          ),
          BlocProvider<RegisterCameraBloc>(
            create: (_) => RegisterCameraBloc(api: apiDataSource),
          ),
          BlocProvider<LiveViewBloc>(
            create: (_) => LiveViewBloc(api: apiDataSource),
          ),
          BlocProvider<FireLogsBloc>(
            create: (_) => FireLogsBloc(api: apiDataSource),
          ),
        ],
        child: MaterialApp(
          title: 'FireWatch',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          initialRoute: AppRouter.serverConfig,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
