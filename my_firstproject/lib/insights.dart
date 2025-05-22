import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
         bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.2),
          child: Divider(
            thickness: 0.5,
            height: 0.5,
            color: Colors.grey,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Money Earned", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildInsightCard(
              title: "Total money earned to date",
              icon: Icons.account_balance_wallet_outlined,
              value: "₹20000",
              subtitle: "Money Collected from 800 orders",
            ),
            SizedBox(height: 24),
            Text("Your Impact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildInsightCard(
              title: "Total waste collected to date",
              icon: Icons.recycling_outlined,
              value: "2000 Kgs",
              subtitle: "Waste Collected from 800 Orders",
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: "Pickups"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Connect"),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: "Insights"),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Icon(Icons.keyboard_arrow_down),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade300),
          SizedBox(height: 16),
          // Center Icon and Values
          Center(child: Icon(icon, size: 48, color: Colors.blueAccent)),
          SizedBox(height: 12),
          Center(child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          SizedBox(height: 8),
          Center(child: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
        ],
      ),
    );
  }
}
