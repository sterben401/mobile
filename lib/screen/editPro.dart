import 'package:flutter/material.dart';

class EditPage extends StatelessWidget {
  final List<dynamic> usersData;

  const EditPage({super.key, required this.usersData});

  @override
  Widget build(BuildContext context) {
    // Display the user data in the EditPage
    // Example: you can use ListView.builder to display each user's data
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Page'),
      ),
      body: ListView.builder(
        itemCount: usersData.length,
        itemBuilder: (context, index) {
          // Assuming each user data item is a Map<String, dynamic>
          var user = usersData[index] as Map<String, dynamic>;
          return ListTile(
            title: Text(user['firstname'] ?? ''),
            subtitle: Text(user['lastname'] ?? ''),
            // Add more fields here as needed
          );
        },
      ),
    );
  }
}