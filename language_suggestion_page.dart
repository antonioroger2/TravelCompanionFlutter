import 'package:flutter/material.dart';

class LanguageSuggestionPage extends StatefulWidget {
  const LanguageSuggestionPage({super.key});

  @override
  _LanguageSuggestionPageState createState() => _LanguageSuggestionPageState();
}

class _LanguageSuggestionPageState extends State<LanguageSuggestionPage> {
  String selectedLanguage = 'Tamil';
  final List<String> languages = [
    'Tamil',
    'Malayalam',
    'Telugu',
    'Kannada',
    'Hindi'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Suggestion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: selectedLanguage,
              items: languages.map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedLanguage = newValue!;
                });
              },
            ),
            const SizedBox(height: 20),
            Text('Selected Language: $selectedLanguage'),
          ],
        ),
      ),
    );
  }
}
