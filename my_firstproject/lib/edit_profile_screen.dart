import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // ✅ Navigate back to Profile page
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.2),
          child: Divider(
            thickness: 1.2,
            height: 1.2,
            color: Colors.grey,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Stack to overlap the image over the card with shadow
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 60),
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(label: 'Name', initialValue: 'Tara Thomas'),
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'Email Address',
                        initialValue: 'tarathomas123@gmail.com'),
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'Mobile Number', initialValue: '9160668022'),
                  ],
                ),
              ),
              // ✅ Circle Avatar above card
              const CircleAvatar(
                radius: 45,
                backgroundColor: Colors.teal,
                child: CircleAvatar(
                  radius: 42,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ✅ Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Save logic goes here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACC1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white, // ✅ White text
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required String initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
