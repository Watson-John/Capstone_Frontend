import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const int _minBytes = 250;
const int _maxBytes = 20 * 1024 * 1024; // 20 MB

class ScanButton extends StatefulWidget {
  const ScanButton({
    super.key,
    this.onImageCaptured,
  });

  /// Called with the validated, compressed image file when the user
  /// successfully selects a receipt. If null, the button shows a placeholder
  /// snackbar (useful for development before wiring up the scan flow).
  final Future<void> Function(XFile image)? onImageCaptured;

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> {
  bool _isPressed = false;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick and compress an image from [source].
  /// Returns null if the user cancelled or the image fails validation.
  Future<XFile?> _pickAndCompress(ImageSource source) async {
    // First pass: 85% quality, max 2048px.
    XFile? image = await _imagePicker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );

    if (image == null) return null;

    // If the compressed result is still over 20 MB, try a harder compression.
    int size = await File(image.path).length();
    if (size > _maxBytes) {
      final recompressed = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 60,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (recompressed != null) {
        image = recompressed;
        size = await File(image.path).length();
      }
    }

    if (!mounted) return null;

    if (size < _minBytes) {
      _showMessage('Image is too small to process.');
      return null;
    }
    if (size > _maxBytes) {
      _showMessage('Image is too large even after compression. Try a smaller photo.');
      return null;
    }

    return image;
  }

  Future<void> _takePhotoWithSystemCamera() async {
    try {
      final image = await _pickAndCompress(ImageSource.camera);
      if (!mounted) return;
      if (image == null) {
        _showMessage('Photo capture cancelled.');
        return;
      }
      await _handleImage(image);
    } catch (error) {
      debugPrint('Unexpected error while opening system camera: $error');
      if (!mounted) return;
      _showMessage('Unable to open camera right now.');
    }
  }

  Future<void> _chooseFromDevice() async {
    try {
      final image = await _pickAndCompress(ImageSource.gallery);
      if (!mounted) return;
      if (image == null) {
        _showMessage('No image selected.');
        return;
      }
      await _handleImage(image);
    } catch (error) {
      debugPrint('Unexpected error while opening gallery: $error');
      if (!mounted) return;
      _showMessage('Unable to open device gallery right now.');
    }
  }

  Future<void> _handleImage(XFile image) async {
    if (widget.onImageCaptured != null) {
      await widget.onImageCaptured!(image);
    } else {
      debugPrint('ScanButton: image selected at ${image.path} (no handler wired)');
      _showMessage('Image selected successfully.');
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
      label: 'Scan Receipt',
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
