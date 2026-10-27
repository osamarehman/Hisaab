import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_config.dart';
import '../../services/log_service.dart';
import 'ledger_style.dart';

/// Opens the camera or gallery and returns a downscaled JPEG/PNG, or null if cancelled.
Future<File?> pickReceipt(ImageSource source) async {
  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 80,
    );
    return picked == null ? null : File(picked.path);
  } catch (e) {
    LogService.instance.error('Receipt', 'Image pick failed: ${e.runtimeType}');
    return null;
  }
}

/// Bottom sheet asking "Take photo / From gallery"; returns the picked file.
Future<File?> showReceiptSourceSheet(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ReceiptSourceButtons(
          onPick: (s) => Navigator.of(context).pop(s),
          takePhotoLabel: l.receiptTakePhoto,
          galleryLabel: l.receiptFromGallery,
        ),
      ),
    ),
  );
  return source == null ? null : pickReceipt(source);
}

/// Two dashed 88px tiles: "Take photo" and "From gallery".
class ReceiptSourceButtons extends StatelessWidget {
  const ReceiptSourceButtons({
    super.key,
    required this.onPick,
    required this.takePhotoLabel,
    required this.galleryLabel,
  });

  final ValueChanged<ImageSource> onPick;
  final String takePhotoLabel;
  final String galleryLabel;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    Widget tile(IconData icon, String label, ImageSource source) => Expanded(
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
              side: BorderSide(color: c.ink),
            ),
            child: InkWell(
              onTap: () => onPick(source),
              child: SizedBox(
                height: 88,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: c.ink),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        tile(Icons.photo_camera_outlined, takePhotoLabel, ImageSource.camera),
        const SizedBox(width: 10),
        tile(Icons.image_outlined, galleryLabel, ImageSource.gallery),
      ],
    );
  }
}

/// Absolute URL for an attachment (the API may return a path).
String resolveAttachmentUrl(String url) =>
    url.startsWith('/') ? '${ApiConfig.baseUrl}$url' : url;

/// Receipt image from the API's attachment endpoint, which needs API auth.
class ReceiptImage extends StatelessWidget {
  const ReceiptImage({
    super.key,
    required this.url,
    required this.accessToken,
    this.height = 220,
  });

  final String url;
  final String accessToken;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    return Image.network(
      resolveAttachmentUrl(url),
      headers: ApiConfig.getAuthHeaders(accessToken),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, _, __) => SizedBox(
        height: height,
        child: Center(
          child: Icon(Icons.receipt_long_outlined, size: 40, color: c.muted),
        ),
      ),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : SizedBox(
              height: height,
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
