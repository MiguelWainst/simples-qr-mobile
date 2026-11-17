import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectedPhoto {
  const SelectedPhoto(this.bytes, this.extension, this.contentType);
  final Uint8List bytes;
  final String extension, contentType;
  static const maxBytes = 5 * 1024 * 1024;

  static SelectedPhoto fromBytes(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const FormatException('Escolha uma foto de até 5 MB.');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return SelectedPhoto(bytes, 'jpg', 'image/jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71 &&
        bytes[4] == 13 &&
        bytes[5] == 10 &&
        bytes[6] == 26 &&
        bytes[7] == 10) {
      return SelectedPhoto(bytes, 'png', 'image/png');
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
      return SelectedPhoto(bytes, 'webp', 'image/webp');
    }
    throw const FormatException(
      'Formato não suportado. Escolha uma foto JPG, PNG ou WebP.',
    );
  }
}

class PhotoRepository {
  PhotoRepository(this.client, {ImagePicker? picker})
    : picker = picker ?? ImagePicker();
  final SupabaseClient client;
  final ImagePicker picker;
  static const bucket = 'menu-photos';

  Future<SelectedPhoto?> pick() async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 75,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    if (await file.length().timeout(const Duration(seconds: 15)) >
        SelectedPhoto.maxBytes) {
      throw const FormatException(
        'A foto ainda ficou maior que 5 MB. Escolha uma imagem menor.',
      );
    }
    return SelectedPhoto.fromBytes(
      await file.readAsBytes().timeout(const Duration(seconds: 15)),
    );
  }

  Future<String> upload(SelectedPhoto photo) async {
    final user = client.auth.currentUser;
    if (user == null)
      throw const FormatException('Entre novamente para enviar a foto.');
    final random = Random.secure();
    final token = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final path = '${user.id}/$token.${photo.extension}';
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          photo.bytes,
          fileOptions: FileOptions(
            contentType: photo.contentType,
            cacheControl: '31536000',
          ),
        )
        .timeout(const Duration(seconds: 45));
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
