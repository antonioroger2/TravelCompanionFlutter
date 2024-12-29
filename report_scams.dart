import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color.fromRGBO(255, 255, 255, 0.907),

      cardTheme: CardTheme(
        elevation: 4,
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    ),
    home: ScamReportPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class ScamReportPage extends StatefulWidget {
  @override
  _ScamReportPageState createState() => _ScamReportPageState();
}

class _ScamReportPageState extends State<ScamReportPage> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;
  bool showReportForm = true;
  bool showSearchForm = true;
  String firstName = 'Guest';
  List<Map<String, dynamic>> searchResults = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('intel')
            .where('email', isEqualTo: user.email)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          var docSnapshot = querySnapshot.docs[0];
          setState(() {
            firstName = docSnapshot['firstName'] ?? 'Guest';
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching user data');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> reportScam() async {
    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showErrorSnackBar('You must be logged in to report a scam');
        return;
      }

      final location = locationController.text.trim();
      final content = contentController.text.trim();

      if (location.isEmpty || content.isEmpty) {
        _showErrorSnackBar('Please fill in all fields');
        return;
      }

      await FirebaseFirestore.instance.collection('scams').add({
        'location': location,
        'content': content,
        'userEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Scam reported successfully!');

      locationController.clear();
      contentController.clear();
      

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
      

      await performSearch(location);
    } catch (e) {
      _showErrorSnackBar('Error reporting scam');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<List<String>> fetchSuggestions(String query) async {
    if (query.isEmpty) return [];
    const apiKey = '492cdff6b79e46adb5938059495eacc9';
    final url = Uri.parse(
        'https://api.opencagedata.com/geocode/v1/json?q=$query&key=$apiKey&limit=2');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(
          data['results'].map((result) => result['formatted'] ?? ''),
        );
      } else {
        print('Error fetching suggestions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final normalizedQuery = query.toLowerCase();

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('scams')
          .orderBy('timestamp', descending: true)
          .get();

      final filteredScams = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final location = (data['location'] ?? '').toString().toLowerCase();
        final content = (data['content'] ?? '').toString().toLowerCase();

        return location.contains(normalizedQuery) ||
               normalizedQuery.contains(location) ||
               content.contains(normalizedQuery);
      }).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
          'timestamp': data['timestamp']?.toDate(),
        };
      }).toList();

      setState(() {
        searchResults = filteredScams;
      });
    } catch (e) {
      _showErrorSnackBar('Error searching for scams');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () {
                  // home
                },
              ),
            Text(
                '  Scam Alerts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(221, 255, 255, 255), 
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.grey.withOpacity(0.1),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              )

          ],
        ),
        backgroundColor: Colors.blue[600],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          firstName,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                title: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, 
                                         color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text(
                                      'Report a Scam',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    showReportForm 
                                        ? Icons.keyboard_arrow_up 
                                        : Icons.keyboard_arrow_down,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showReportForm = !showReportForm;
                                    });
                                  },
                                ),
                              ),
                              if (showReportForm)
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      TypeAheadField(
                                        textFieldConfiguration: TextFieldConfiguration(
                                          controller: locationController,
                                          decoration: InputDecoration(
                                            labelText: 'Location',
                                            prefixIcon: Icon(Icons.location_pin),
                                          ),
                                        ),
                                        suggestionsCallback: fetchSuggestions,
                                        itemBuilder: (context, String suggestion) {
                                          return ListTile(
                                            leading: Icon(Icons.location_on),
                                            title: Text(suggestion),
                                          );
                                        },
                                        onSuggestionSelected: (String suggestion) {
                                          locationController.text = suggestion;
                                        },
                                      ),
                                      SizedBox(height: 16),
                                      TextField(
                                        controller: contentController,
                                        decoration: InputDecoration(
                                          labelText: 'Describe the scam in detail...',
                                          alignLabelWithHint: true,
                                        ),
                                        maxLines: 4,
                                      ),
                                     SizedBox(height: 16),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: isSubmitting ? null : reportScam,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: isSubmitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Submit Report',
              style: TextStyle(fontSize: 16),
            ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.9), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                title: Row(
                                  children: [
                                    Icon(Icons.search, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Search Reported Scams',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    showSearchForm 
                                        ? Icons.keyboard_arrow_up 
                                        : Icons.keyboard_arrow_down,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showSearchForm = !showSearchForm;
                                    });
                                  },
                                ),
                              ),
                              if (showSearchForm)
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      TypeAheadField(
                                        textFieldConfiguration: TextFieldConfiguration(
                                          controller: searchController,
                                          decoration: InputDecoration(
                                            labelText: 'Search by Location or Content',
                                            prefixIcon: Icon(Icons.search),
                                          ),
                                        ),
                                        suggestionsCallback: fetchSuggestions,
                                        itemBuilder: (context, String suggestion) {
                                          return ListTile(
                                            leading: Icon(Icons.location_on),
                                            title: Text(suggestion),
                                          );
                                        },
                                        onSuggestionSelected: (String suggestion) {
                                          searchController.text = suggestion;
                                          performSearch(suggestion);
                                        },
                                      ),
                                      SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            performSearch(searchController.text.trim());
                                            setState(() {
                                              showReportForm = false;
                                              showSearchForm = false;
                                            });
                                          },
                                          icon: Icon(Icons.search),
                                          label: Text('Search'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white.withOpacity(0.9), 
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (searchResults.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Search Results',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final result = searchResults[index];
                              final timestamp = result['timestamp'] as DateTime?;
                              final formattedDate = timestamp != null
                                  ? DateFormat('MMM d, yyyy h:mm a').format(timestamp)
                                  : 'Date unknown';
                              
                              return Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, 
                                               color: Colors.blue[600]),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              result['location'] ?? 'Unknown Location',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        result['content'] ?? 'No Details',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ] else if (searchController.text.isNotEmpty) ...[
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No scams reported in this area yet.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        

                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
