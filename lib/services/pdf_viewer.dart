import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'http.dart';

class PdfViewerPage extends StatefulWidget {
  final ApiParams apiParams;
  const PdfViewerPage({super.key, required this.apiParams});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool isLoading = true;
  bool isError = false;
  String screenTitle = 'Загрузка...';
  late Uint8List fileData;

  Future<void> apiRequest() async {
    final response = await Http.mobApp(widget.apiParams);
    try {
      if (response?['Error'] != null && response['Error'] == 0) {
        String base64string = response['FileData'] ?? response['Data']['FileData'];
        base64string = base64string.replaceAll('\r\n', '').trim();
        setState(() {
          fileData = base64Decode(base64string);
          screenTitle = response['FileName'] ?? response['Data']['FileName'];
          isLoading = false;
        });
      }
      else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      print(response);
      setState(() {
        isError = true;
        isLoading = false;
      });
    }

  }

  @override
  void initState() {
    apiRequest();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : isError
          ? const Center(child: Text('Ошибка загрузки файла'))
          : Center(
            child: PDFView(
              pdfData: fileData,
              onError: (error) {
                print(error.toString());
              },
            ),
          ),
    );
  }
}
