// lib/presentation/screens/register_camera_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../blocs/other_blocs.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterCameraScreen extends StatefulWidget {
  const RegisterCameraScreen({super.key});

  @override
  State<RegisterCameraScreen> createState() => _RegisterCameraScreenState();
}

class _RegisterCameraScreenState extends State<RegisterCameraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _camIdController = TextEditingController();
  final _streamUrlController = TextEditingController();
  int _frameSkip = 0;
  String? _selectedFilePath;
  String? _selectedFileName;

  // Toggle between video upload and stream URL
  bool _isVideoMode = true;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'avi', 'mov', 'mkv'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isVideoMode) {
      if (_selectedFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a video file')),
        );
        return;
      }
      context.read<RegisterCameraBloc>().add(
            RegisterWithVideoRequested(
              camId: _camIdController.text.trim(),
              filePath: _selectedFilePath!,
              frameSkip: _frameSkip,
            ),
          );
    } else {
      context.read<RegisterCameraBloc>().add(
            RegisterWithStreamRequested(
              camId: _camIdController.text.trim(),
              url: _streamUrlController.text.trim(),
              frameSkip: _frameSkip,
            ),
          );
    }
  }

  @override
  void dispose() {
    _camIdController.dispose();
    _streamUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Camera'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<RegisterCameraBloc, RegisterCameraState>(
        listener: (context, state) {
          if (state is RegisterCameraSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Go to camera list
            Navigator.pushReplacementNamed(context, AppRouter.cameraList);
          } else if (state is RegisterCameraFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Camera ID
                _SectionLabel('Camera ID'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _camIdController,
                  decoration: const InputDecoration(
                    labelText: 'Camera ID',
                    hintText: 'e.g. cam_entrance, roof_cam',
                    prefixIcon: Icon(Icons.videocam_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a camera ID';
                    if (v.contains(' ')) return 'No spaces allowed';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Source type toggle
                _SectionLabel('Source Type'),
                const SizedBox(height: 8),
                _SourceToggle(
                  isVideoMode: _isVideoMode,
                  onChanged: (val) => setState(() => _isVideoMode = val),
                ),
                const SizedBox(height: 20),

                // Video picker or stream URL
                if (_isVideoMode) ...[
                  _SectionLabel('Video File'),
                  const SizedBox(height: 8),
                  _VideoPickerCard(
                    fileName: _selectedFileName,
                    onTap: _pickVideo,
                  ),
                ] else ...[
                  _SectionLabel('Stream URL'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _streamUrlController,
                    decoration: const InputDecoration(
                      labelText: 'RTSP / HTTP URL',
                      hintText: 'rtsp://192.168.1.10:554/stream',
                      prefixIcon: Icon(Icons.link_rounded, size: 20),
                    ),
                    validator: (v) {
                      if (!_isVideoMode && (v == null || v.isEmpty)) {
                        return 'Enter stream URL';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Frame skip
                _SectionLabel('Frame Skip  ($_frameSkip)'),
                const SizedBox(height: 4),
                Text(
                  _frameSkip == 0
                      ? 'Every frame processed (max accuracy)'
                      : 'Every ${_frameSkip}th frame (reduced CPU)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _frameSkip.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  activeColor: AppTheme.accent,
                  label: _frameSkip.toString(),
                  onChanged: (v) => setState(() => _frameSkip = v.toInt()),
                ),

                const SizedBox(height: 32),

                // Submit button
                BlocBuilder<RegisterCameraBloc, RegisterCameraState>(
                  builder: (context, state) {
                    final isLoading = state is RegisterCameraLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _onSubmit,
                        icon: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_circle_outline_rounded),
                        label: Text(
                          isLoading ? 'Registering...' : 'Register Camera',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: AppTheme.textSecondary,
          ),
    );
  }
}

class _SourceToggle extends StatelessWidget {
  final bool isVideoMode;
  final ValueChanged<bool> onChanged;

  const _SourceToggle({required this.isVideoMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Video Upload',
            icon: Icons.upload_file_rounded,
            selected: isVideoMode,
            onTap: () => onChanged(true),
          ),
          _Tab(
            label: 'RTSP Stream',
            icon: Icons.live_tv_rounded,
            selected: !isVideoMode,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPickerCard extends StatelessWidget {
  final String? fileName;
  final VoidCallback onTap;

  const _VideoPickerCard({this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: fileName != null ? AppTheme.accent : AppTheme.divider,
            width: fileName != null ? 1 : 0.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              fileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: fileName != null ? AppTheme.accent : AppTheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              fileName ?? 'Tap to choose video file',
              style: TextStyle(
                color: fileName != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (fileName == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'mp4, avi, mov, mkv',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
