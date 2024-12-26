import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../models/pdfFileModel.dart';
import '../controller/pdfEditor_controller.dart';

class PDFPickerView extends StatelessWidget {
  PDFPickerView({Key? key}) : super(key: key);

  final PDFController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select a PDF',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 4,
        shadowColor: Colors.indigoAccent.withOpacity(0.5),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: controller.pickPDFFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, size: 24, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Pick PDF from Device',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Obx(
                () => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                    : controller.recentFiles.isEmpty
                        ? const Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No Recent PDFs',
                                    style: TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: controller.recentFiles.length,
                              itemBuilder: (context, index) {
                                final PDFFile file = controller.recentFiles[index];
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shadowColor: Colors.indigoAccent.withOpacity(0.2),
                                  elevation: 4,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo.shade100,
                                      child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                    ),
                                    title: Text(
                                      file.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.indigo,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Last opened: ${file.timestamp}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.indigo),
                                      onPressed: () => controller.openPDF(file.path),
                                    ),
                                    onTap: () => controller.openPDF(file.path),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
