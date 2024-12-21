import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/homeController.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildUploadSection(context),
                const SizedBox(height: 40),
                _buildConvertButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            const Text(
              'PDF Language ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Text(
              'Converter',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Convert your PDF documents to different languages instantly',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDropZone(context),
          const SizedBox(height: 32),
          _buildLanguageSelection(),
        ],
      ),
    );
  }

  Widget _buildDropZone(BuildContext context) {
    return Obx(() {
      return GestureDetector(
        onTap: () async {
          if (!controller.isLoading.value) {
            await controller.selectFile();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: 32,
              horizontal: MediaQuery.of(context).size.width * 0.2),
          decoration: BoxDecoration(
            color: controller.isFileSelected.value
                ? Colors.blue.shade50
                : const Color(0xFFEBF4FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: controller.isFileSelected.value
                  ? Colors.blue.shade400
                  : const Color(0xFF4299E1),
              width: 2,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
          ),
          child: Column(
            children: [
              if (controller.isFileSelected.value) ...[
                // Selected file UI
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 40,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.fileName.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PDF Document',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: controller.clearSelectedFile,
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade600,
                      ),
                      tooltip: 'Remove file',
                    ),
                  ],
                ),
              ] else ...[
                // File selection UI
                const Icon(
                  Icons.upload_file_rounded,
                  size: 56,
                  color: Color(0xFF4299E1),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select PDF file',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click to browser',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLanguageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Languages',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _LanguageDropdown(
                label: 'From',
                value: controller.selectedFromLanguage,
                onChanged: controller.setFromLanguage,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildSwapButton(),
            ),
            Expanded(
              child: _LanguageDropdown(
                label: 'To',
                value: controller.selectedToLanguage,
                onChanged: controller.setToLanguage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwapButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.swapLanguages,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.swap_horiz_rounded,
            color: Colors.blue.shade400,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildConvertButton() {
    return Obx(() {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: controller.isFileSelected.value ? 1.0 : 0.5,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed:
                controller.isFileSelected.value ? controller.convertPDF : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: controller.isFileSelected.value ? 3 : 0,
              shadowColor: Colors.blue.shade200,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.translate_rounded,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Convert PDF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _LanguageDropdown extends StatelessWidget {
  final String label;
  final RxString value;
  final Function(String) onChanged;

  const _LanguageDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(() {
            return DropdownButton<String>(
              value: value.value,
              items: [
                'English',
                'Spanish',
                'French',
                'German',
                'Chinese',
                'Japanese',
                'Korean',
                'Russian',
                'malayalam'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 15,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) => onChanged(newValue!),
              isExpanded: true,
              underline: Container(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.blue.shade400,
              ),
            );
          }),
        ),
      ],
    );
  }
}
