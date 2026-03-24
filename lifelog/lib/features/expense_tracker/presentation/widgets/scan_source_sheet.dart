import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'add_option_tile.dart';

void showScanSourceSheet(
  BuildContext context, {
  required Future<void> Function(ImageSource source) onSourceSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetCtx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              AddOptionTile(
                icon: Icons.photo_camera_outlined,
                iconColor: Theme.of(sheetCtx).colorScheme.secondary,
                title: 'Take Photo',
                subtitle: 'Use camera',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onSourceSelected(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              AddOptionTile(
                icon: Icons.photo_library_outlined,
                iconColor: Theme.of(sheetCtx).colorScheme.secondary,
                title: 'Choose From Device',
                subtitle: 'Pick from gallery',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  onSourceSelected(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
