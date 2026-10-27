import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet to choose Camera or Gallery, then returns the
/// picked file (or null if the user picked nothing / cancelled).
Future<XFile?> pickImageFromSource(
  BuildContext context, {
  ImageSource? directSource,
  String? title,
}) async {
  if (directSource != null) {
    final picker = ImagePicker();
    return picker.pickImage(source: directSource, imageQuality: 90);
  }

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.sp12),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp24,
                vertical: AppTheme.sp8,
              ),
              child: Text(
                title ?? 'Scan Sheet',
                style: AppTextStyles.headlineSmall(),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text('Take photo', style: AppTextStyles.titleMedium()),
              subtitle: Text('Capture sheet using camera', style: AppTextStyles.bodySmall(color: AppColors.textSecondary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text('Upload from gallery', style: AppTextStyles.titleMedium()),
              subtitle: Text('Choose image from device gallery', style: AppTextStyles.bodySmall(color: AppColors.textSecondary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return null;
  final picker = ImagePicker();
  return picker.pickImage(source: source, imageQuality: 90);
}
