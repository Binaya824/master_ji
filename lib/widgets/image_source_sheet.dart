import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'image_crop_screen.dart';
import 'omr_scan_guide.dart';

/// Shows a bottom sheet to choose Camera or Gallery, then returns the
/// cropped/straightened file (or null if the user picked or cropped
/// nothing / cancelled).
Future<XFile?> pickImageFromSource(
  BuildContext context, {
  ImageSource? directSource,
  String? title,
}) async {
  if (directSource != null) {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: directSource, imageQuality: 90);
    if (file == null || !context.mounted) return null;
    return _crop(context, file);
  }

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp24,
          vertical: AppTheme.sp12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.sp8),
              child: Text(
                title ?? 'Scan Sheet',
                style: AppTextStyles.headlineSmall(),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppTheme.sp16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const ScanGuidePreview(),
                      const SizedBox(height: AppTheme.sp8),
                      Text(
                        'Frame only the\nanswer-bubble block',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.sp16),
                Expanded(
                  child: Column(
                    children: [
                      _SourceOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Take photo',
                        subtitle: 'Use camera',
                        onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      ),
                      const SizedBox(height: AppTheme.sp12),
                      _SourceOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Upload',
                        subtitle: 'From gallery',
                        onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return null;
  final picker = ImagePicker();
  final file = await picker.pickImage(source: source, imageQuality: 90);
  if (file == null || !context.mounted) return null;
  return _crop(context, file);
}

/// Pushes the perspective-crop/rotate screen over [file] and returns the
/// cropped result, or null if the user cancelled.
Future<XFile?> _crop(BuildContext context, XFile file) async {
  final bytes = await file.readAsBytes();
  if (!context.mounted) return null;
  return Navigator.of(context).push<XFile>(
    MaterialPageRoute(builder: (_) => ImageCropScreen(bytes: bytes)),
  );
}

/// Compact tappable card used for the Camera/Gallery choices next to the
/// scan guide preview.
class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.sp16,
            horizontal: AppTheme.sp12,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: AppTheme.sp8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium(),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
