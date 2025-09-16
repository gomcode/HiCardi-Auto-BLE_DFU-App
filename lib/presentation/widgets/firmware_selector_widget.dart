import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FirmwareSelectorWidget extends StatelessWidget {
  final File? selectedFile;
  final Function(File) onFileSelected;

  const FirmwareSelectorWidget({
    super.key,
    required this.selectedFile,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.folder_zip, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedFile != null
                  ? selectedFile!.path.split('/').last
                  : '펌웨어 파일을 선택하세요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: selectedFile != null
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: selectedFile != null
                    ? Colors.blue
                    : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.attach_file, size: 20),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['zip'],
              );
              if (result != null) {
                onFileSelected(File(result.files.single.path!));
              }
            },
            tooltip: 'ZIP 파일 선택',
          ),
        ],
      ),
    );
  }
}