import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ controllers/cv_controller.dart';


class UploadPage extends StatelessWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload CV'),
      ),
      body: Consumer<CvController>(
        builder: (context, controller, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Upload your CV for analysis\n(PDF or DOCX)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: Text(
                      controller.selectedFile != null 
                          ? 'Change File'
                          : 'Choose File',
                    ),
                    onPressed: controller.isLoading
                        ? null
                        : () async {
                            try {
                              await controller.uploadAndAnalyzeCV();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                  ),
                  // Rest of the UI code remains the same
                  // ...
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Alternative approach using Provider.of instead of Consumer
class UploadPageAlternative extends StatelessWidget {
  const UploadPageAlternative({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload CV'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.upload_file,
                size: 80,
                color: Colors.blue,
              ),
              // Rest of the UI using controller directly
              // ...
            ],
          ),
        ),
      ),
    );
  }
}
