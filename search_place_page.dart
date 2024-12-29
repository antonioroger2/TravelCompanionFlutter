import 'package:flutter/material.dart';

class SearchPlacePage extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();

  SearchPlacePage({super.key});

  void _searchPlace() {
    // Implement search place logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search by Place'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Type a place where you want to visit',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _searchPlace,
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }
}
