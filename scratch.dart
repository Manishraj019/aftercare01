void main() {
  String id = 'menu_001___';
  var parts = id.split('_');
  var baseId = parts.sublist(0, parts.length - 3).join('_');
  print('Base ID: $baseId');
}
