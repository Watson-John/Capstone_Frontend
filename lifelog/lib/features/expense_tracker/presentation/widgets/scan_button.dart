import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanButton extends StatefulWidget {
  const ScanButton({super.key});

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> {
  bool _isPressed = false;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _takePhotoWithSystemCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted) return;

      if (image == null) {
        _showMessage('Photo capture cancelled.');
        return;
      }

      debugPrint('Captured image path: ${image.path}');
      _showMessage('Photo captured successfully.');
    } catch (error) {
      debugPrint('Unexpected error while opening system camera: $error');
      if (!mounted) return;
      _showMessage('Unable to open camera right now.');
    }
  }

  Future<void> _chooseFromDevice() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;

      if (image == null) {
        _showMessage('No image selected.');
        return;
      }

      debugPrint('Selected image path: ${image.path}');
      _showMessage('Image selected successfully.');
    } catch (error) {
      debugPrint('Unexpected error while opening gallery: $error');
      if (!mounted) return;
      _showMessage('Unable to open device gallery right now.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showScanOptionsSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Receipt',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Capture a new photo or upload one from your device.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SheetActionButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Take Photo',
                      subtitle: 'Use camera',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _takePhotoWithSystemCamera();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetActionButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Choose From Device',
                      subtitle: 'Pick from gallery',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _chooseFromDevice();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(_isPressed ? 16 : 28);
    final backgroundColor = _isPressed
        ? colorScheme.primaryContainer
        : colorScheme.primary;
    final foregroundColor = _isPressed
        ? colorScheme.onPrimaryContainer
        : colorScheme.onPrimary;

    return Semantics(
      button: true,
      label: 'Scan Button',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showScanOptionsSheet,
          onHighlightChanged: (isHighlighted) {
            setState(() {
              _isPressed = isHighlighted;
            });
          },
          borderRadius: borderRadius,
          child: SizedBox(
            width: 64,
            height: 64,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                scale: _isPressed ? 0.94 : 1,
                child: Icon(
                  Icons.document_scanner,
                  color: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    this.icon = Icons.help_outline,
    this.label = 'Action',
    this.subtitle = '',
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final buttonBackground = colorScheme.secondaryContainer;
    final buttonForeground = colorScheme.onSecondaryContainer;

    return Material(
      color: buttonBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.onPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: buttonForeground,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: buttonForeground,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
