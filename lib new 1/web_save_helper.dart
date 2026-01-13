// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void saveFile(List<int> bytes, String fileName, String format) {
  final base64Data = base64Encode(bytes);
  final mimeType = format == 'xlsx' 
      ? "application/octet-stream" 
      : "text/csv";
      
  html.AnchorElement(href: "data:$mimeType;base64,$base64Data")
    ..setAttribute("download", "$fileName.$format")
    ..click();
}
