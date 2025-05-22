import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.arrow_back),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
           
          )
        ],
        // ✅ Divider directly under AppBar
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
          // ✅ Profile Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage('assets/profile.jpg'),
              ),
              title: const Text('Tara Thomas'),
              subtitle: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },

               child: Row(mainAxisSize: MainAxisSize.min,
                  children:const[
                    Text('Edit Profile',style:TextStyle(color:Colors.teal),),
                    SizedBox(width: 4,),
                    Icon(Icons.arrow_forward_ios, size:12,color:Colors.teal),
                  ]
               )
                 
              ),
             
            ),
          ),

          // ✅ Divider under profile card
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
        
          ),

          // ✅ Grouped Section: Previous orders → Privacy Policy
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildMenuItem('Previous orders'),
                const Divider(height: 1),
                _buildMenuItem('Addresses'),
                const Divider(height: 1),
                _buildMenuItem('Customer Support'),
                const Divider(height: 1),
                _buildMenuItem('Terms & Conditions'),
                const Divider(height: 1),
                _buildMenuItem('Privacy Policy'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Grouped Section: Delete + Logout
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildMenuItem('Delete Account'),
                const Divider(height: 1),
                _buildMenuItem('Logout'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}


