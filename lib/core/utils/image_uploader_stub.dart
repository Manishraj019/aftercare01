import 'package:flutter/material.dart';

/// Stub implementation of pickLocalImage for non-web platforms.
/// Opens a beautiful custom dialog letting the user enter a local file path,
/// paste a URL, or choose a culinary preset image.
Future<String?> pickLocalImage(BuildContext context) async {
  final controller = TextEditingController();
  String? selectedImage;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.image, color: Colors.blue),
          SizedBox(width: 8),
          Text('Choose Food Photo'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pasting image URLs often fails due to network/CORS blocks. '
              'For the best local demo experience, you can select a culinary preset below, '
              'or enter the path to a local image file on your computer.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Local File Path or Image URL',
                hintText: 'e.g. C:/Users/name/Pictures/burger.jpg',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delicious Local Presets:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // A gorgeous grid of culinary presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetOption(
                  context,
                  'Premium Pizza 🍕',
                  'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=600&q=80',
                  (val) { selectedImage = val; Navigator.pop(context); }
                ),
                _presetOption(
                  context,
                  'Truffle Pasta 🍝',
                  'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?auto=format&fit=crop&w=600&q=80',
                  (val) { selectedImage = val; Navigator.pop(context); }
                ),
                _presetOption(
                  context,
                  'Gourmet Burger 🍔',
                  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
                  (val) { selectedImage = val; Navigator.pop(context); }
                ),
                _presetOption(
                  context,
                  'Greek Salad 🥗',
                  'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80',
                  (val) { selectedImage = val; Navigator.pop(context); }
                ),
                _presetOption(
                  context,
                  'Lava Cake 🍰',
                  'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=600&q=80',
                  (val) { selectedImage = val; Navigator.pop(context); }
                ),
                _presetOption(
                  context,
                  'Mojito 🍹',
                  'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
                  (val) { selectedImage = val; Navigator.pop(context); }
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final val = controller.text.trim();
            if (val.isNotEmpty) {
              selectedImage = val;
            }
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    ),
  );

  return selectedImage;
}

Widget _presetOption(
    BuildContext context, String label, String url, Function(String) onTap) {
  return InkWell(
    onTap: () => onTap(url),
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
