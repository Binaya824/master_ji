import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shows a bottom sheet to choose Camera or Gallery, then returns the
/// picked file (or null if the user picked nothing / cancelled).
Future<XFile?> pickImageFromSource(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;
  final picker = ImagePicker();
  return picker.pickImage(source: source, imageQuality: 90);
}
