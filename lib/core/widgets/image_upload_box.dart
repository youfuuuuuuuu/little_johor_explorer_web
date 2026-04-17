import 'package:flutter/material.dart';

class ImageUploadBox extends StatelessWidget {
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onTap;
  final String label;

  const ImageUploadBox({
    super.key,
    required this.imageUrl,
    required this.isUploading,
    required this.onTap,
    this.label = "Tap to upload image from device",
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isUploading ? Colors.orange : Colors.indigo.shade200,
            width: 2,
          ),
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4), BlendMode.darken),
                )
              : null,
        ),
        child: Center(
          child: isUploading
              ? const CircularProgressIndicator(color: Colors.orange)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasImage
                          ? Icons.published_with_changes_rounded
                          : Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: hasImage ? Colors.white : Colors.indigo.shade300,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasImage ? "Tap to change image" : label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasImage ? Colors.white : Colors.indigo.shade400,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
