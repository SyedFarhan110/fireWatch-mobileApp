// lib/presentation/screens/server_config_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../blocs/health_bloc.dart';
import '../../data/datasources/server_config_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: AppConstants.defaultPort);
  bool _autoConnecting = false;

  @override
  void initState() {
    super.initState();
    _tryAutoConnect();
  }

  Future<void> _tryAutoConnect() async {
    final saved = await ServerConfigService.loadFromPrefs();
    if (saved != null && mounted) {
      setState(() {
        _ipController.text = saved.ip;
        _portController.text = saved.port;
        _autoConnecting = true;
      });
      context.read<HealthBloc>().add(
        HealthCheckRequested(ip: saved.ip, port: saved.port),
      );
    }
  }

  void _onConnect() {
    if (!_formKey.currentState!.validate()) return;
    context.read<HealthBloc>().add(
      HealthCheckRequested(
        ip: _ipController.text.trim(),
        port: _portController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<HealthBloc, HealthState>(
        listener: (context, state) {
          if (state is HealthSuccess) {
            // If cameras already running on server → go straight to list
            // Otherwise → go to register screen
            final destination = state.hasCameras
                ? AppRouter.cameraList
                : AppRouter.registerCamera;
            Navigator.pushReplacementNamed(context, destination);
          } else if (state is HealthFailure) {
            setState(() => _autoConnecting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo / title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.danger.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: AppTheme.danger,
                          size: 40,
                        ),
                      ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'FireWatch',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Connect to your Jetson server',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 56),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server address',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),

                      // IP field
                      TextFormField(
                        controller: _ipController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'IP Address',
                          hintText: '192.168.1.100',
                          prefixIcon: Icon(Icons.dns_rounded, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter IP address';
                          final parts = v.split('.');
                          if (parts.length != 4) return 'Invalid IP format';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Port field
                      TextFormField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '8000',
                          prefixIcon: Icon(
                            Icons.settings_ethernet_rounded,
                            size: 20,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter port';
                          final port = int.tryParse(v);
                          if (port == null || port < 1 || port > 65535) {
                            return 'Port must be 1–65535';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Connect button
                      BlocBuilder<HealthBloc, HealthState>(
                        builder: (context, state) {
                          final isLoading = state is HealthLoading;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _onConnect,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Connect to Jetson'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Auto-connect notice
                if (_autoConnecting)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Reconnecting to last server...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
