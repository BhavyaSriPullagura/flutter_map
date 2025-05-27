import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'connect_screen.dart';

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({Key? key}) : super(key: key);

  @override
  _WritePostScreenState createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  bool isPostButtonEnabled = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    titleController.addListener(_updatePostButtonState);
    bodyController.addListener(_updatePostButtonState);
  }

  void _updatePostButtonState() {
    final isEnabled = titleController.text.trim().isNotEmpty ||
        bodyController.text.trim().isNotEmpty ||
        _selectedImage != null;
    if (isPostButtonEnabled != isEnabled) {
      setState(() {
        isPostButtonEnabled = isEnabled;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  void _handleClose() {
    Navigator.pop(context);
  }

  Future<void> _pickImageFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _updatePostButtonState();
      });
    }
  }

  void _handlePost() {
    final newPost = Post(
      name: 'You',
      timestamp: DateTime.now(),
      title: titleController.text.trim(),
      content: bodyController.text.trim(),
      imageUrl: _selectedImage?.path,
      likes: 0,
      comments: 0,
      shares: 0,
    );

    Navigator.pop(context, newPost);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.015),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, size: width * 0.07),
                    onPressed: _handleClose,
                  ),
                  ElevatedButton(
                    onPressed: isPostButtonEnabled ? _handlePost : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPostButtonEnabled ? Colors.blue : Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: height * 0.01),
                    ),
                    child: Text(
                      'Post',
                      style: TextStyle(
                        color: isPostButtonEnabled ? Colors.white : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Input area
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: width * 0.05),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: bodyController,
                        maxLines: 100,
                        expands: false,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(fontSize: width * 0.045, color: Colors.black87),
                        decoration: const InputDecoration(
                          hintText: 'Body Text',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.file(_selectedImage!, height: 200),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: EdgeInsets.only(
                left: width * 0.04,
                right: width * 0.04,
                bottom: mediaQuery.viewInsets.bottom > 0 ? 0 : height * 0.02,
              ),
              child: Row(
                children: [
                  _BottomIconButton(
                    icon: Icons.camera_alt_outlined,
                    onTap: _pickImageFromCamera,
                  ),
                  const SizedBox(width: 16),
                  _BottomIconButton(
                    icon: Icons.add,
                    onTap: () {
                      // Optionally add gallery pick here
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BottomIconButton({
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 24, color: Colors.black87),
        ),
      ),
    );
  }
}   
