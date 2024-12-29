import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(home: ReportScamsPage()));
}

class ReportScamsPage extends StatefulWidget {
  @override
  _ReportScamsPageState createState() => _ReportScamsPageState();
}

class _ReportScamsPageState extends State<ReportScamsPage> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  String firstName = 'Guest';

  final List<String> citySuggestions = [
    "Paris, France",
    "Dubai, United Arab Emirates",
    "Madrid, Spain",
    "Tokyo, Japan",
    "Amsterdam, Netherlands",
    "Berlin, Germany",
    "Rome, Italy",
    "New York City",
    "Barcelona, Spain",
    "London, United Kingdom",
    "Singapore",
    "Munich, Germany",
    "Milan, Italy",
    "Seoul, South Korea",
    "Dublin, Ireland",
    "Osaka, Japan",
    "Hong Kong",
    "Vienna, Austria",
    "Los Angeles",
    "Lisbon, Portugal",
    "Prague, Czech Republic",
    "Sydney, Australia",
    "Istanbul, Turkey",
    "Melbourne, Australia",
    "Orlando, Florida",
    "Frankfurt, Germany",
    "Kyoto, Japan",
    "Taipei, Taiwan",
    "Florence, Italy",
    "Toronto, Canada",
    "Athens, Greece",
    "Zurich, Switzerland",
    "Bangkok, Thailand",
    "Las Vegas",
    "Miami",
    "Kuala Lumpur, Malaysia",
    "Venice, Italy",
    "Abu Dhabi, United Arab Emirates",
    "Stockholm, Sweden",
    "Brussels, Belgium",
    "Tel Aviv, Israel",
    "San Francisco",
    "Shanghai, China",
    "Warsaw, Poland",
    "Guangzhou, China",
    "Copenhagen, Denmark",
    "Nice, France",
    "Washington, United States",
    "Budapest, Hungary",
    "Shenzhen, China",
    "Vancouver, Canada",
    "Palma de Mallorca, Spain",
    "Seville, Spain",
    "São Paulo, Brazil",
    "Valencia, Spain",
    "Mexico City, Mexico",
    "Antalya, Turkey",
    "Sapporo, Japan",
    "Beijing, China",
    "Busan, South Korea",
    "Fukuoka, Japan",
    "Edinburgh, United Kingdom",
    "Porto, Portugal",
    "Jerusalem, Israel",
    "Kraków, Poland",
    "Rio de Janeiro, Brazil",
    "Honolulu, Hawaii",
    "Montreal, Canada",
    "Macau",
    "Cancún, Mexico",
    "Marne-La-Vallée, France",
    "Doha, Qatar",
    "Sharjah, United Arab Emirates",
    "Rhodes, Greece",
    "Verona, Italy",
    "Bologna, Italy",
    "Thessaloniki, Greece",
    "Buenos Aires, Argentina",
    "Lima, Peru",
    "Phuket, Thailand",
    "Delhi, India",
    "Heraklion, Greece",
    "Tallinn, Estonia",
    "Pattaya-Chonburi, Thailand",
    "Ho Chi Minh City, Vietnam",
    "Playa Del Carmen, Mexico",
    "Johor Bahru, Malaysia",
    "Santiago, Chile",
    "Tbilisi, Georgia",
    "Riyadh, Saudi Arabia",
    "Marrakech, Morocco",
    "Vilnius, Lithuania",
    "Mugla, Turkey",
    "Zhuhai, China",
    "Mecca, Saudi Arabia",
    "Punta Cana, Dominican Republic",
    "Guilin, China",
    "Hanoi, Vietnam",
    "Cairo, Egypt",
    "Muscat, Oman"
  ];

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
      print("Error fetching user data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> reportScam() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to report a scam')),
        );
        return;
      }

      final location = locationController.text.trim();
      final content = contentController.text.trim();

      if (location.isEmpty || content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('scams').add({
        'location': location,
        'content': content,
        'userEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scam reported successfully!')),
      );

      locationController.clear();
      contentController.clear();
    } catch (e) {
      print("Error reporting scam: $e");
    }
  }

  Stream<QuerySnapshot> searchScams(String query) {
    if (query.isEmpty) {
      return FirebaseFirestore.instance
          .collection('scams')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('scams')
          .where('location', isEqualTo: query)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Scams'),
        backgroundColor: Color(0xFF1E88E5),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $firstName',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Report a Scam',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: 'Scam Details',
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: reportScam,
                      child: Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Search Reported Scams',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    SizedBox(height: 10),
                    TypeAheadField(
                      textFieldConfiguration: TextFieldConfiguration(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by Location',
                          suffixIcon:
                              Icon(Icons.search, color: Color(0xFF1E88E5)),
                        ),
                      ),
                      suggestionsCallback: (pattern) {
                        return citySuggestions.where((city) =>
                            city.toLowerCase().contains(pattern.toLowerCase()));
                      },
                      itemBuilder: (context, String suggestion) {
                        return ListTile(title: Text(suggestion));
                      },
                      onSuggestionSelected: (String suggestion) {
                        searchController.text = suggestion;
                        setState(() {});
                      },
                      noItemsFoundBuilder: (context) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No matching locations.',
                          style: TextStyle(color: Color(0xFF757575)),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: searchScams(searchController.text.trim()),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final scams = snapshot.data!.docs;

                        if (scams.isEmpty) {
                          return Text('No scams found.');
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: scams.length,
                          itemBuilder: (context, index) {
                            final scam = scams[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(scam['location']),
                                subtitle: Text(scam['content']),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
