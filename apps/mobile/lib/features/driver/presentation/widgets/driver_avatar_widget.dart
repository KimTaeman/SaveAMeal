import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_profile_provider.dart';

class DriverAvatarWidget extends ConsumerWidget {
  const DriverAvatarWidget({super.key, required this.photoUrl});
  final String? photoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (picked == null) return;
        await ref
            .read(driverProfileProvider.notifier)
            .uploadAvatar(picked.path);
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary, width: 2.5),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: cs.surfaceContainerHigh,
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: photoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Icon(Icons.person, size: 40, color: cs.onSurfaceVariant),
            ),
          ),
          CircleAvatar(
            radius: 13,
            backgroundColor: cs.primary,
            child: Icon(Icons.camera_alt, size: 14, color: cs.onPrimary),
          ),
        ],
      ),
    );
  }
}
