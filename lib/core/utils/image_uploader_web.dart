import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/material.dart';

/// Web implementation of pickLocalImage using HTML file input.
/// Opens the browser's file picker, reads the file as a base64 Data URL, and returns it.
Future<String?> pickLocalImage(BuildContext context) async {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) {
        completer.complete(reader.result as String?);
      });
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}
