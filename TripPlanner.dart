import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class TripPlanner extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const TripPlanner({Key? key, this.locationData}) : super(key: key);

  @override
  TripPlannerState createState() => TripPlannerState();
}

class TripPlannerState extends State<TripPlanner>
    with SingleTickerProviderStateMixin {
  final TextEditingController _destinationController = TextEditingController();
  String? _travelType;
  String? _costPreference;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _itinerary = "";
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> _searchResults = [];

  static const String _apiKey = '492cdff6b79e46adb5938059495eacc9';

  final List<String> _travelTypes = [
    'Adventurous',
    'Sightseeing',
    'Religious',
    'Family',
    'Romantic',
  ];

  final List<String> _costPreferences = [
    'Luxurious (4 of 4)',
    'Moderate (3 of 4)',
    'Economy (2 of 4)',
    'Cheap (1 of 4)',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    if (widget.locationData != null) {
      _destinationController.text = widget.locationData!['destination'] ?? '';
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(query)}&key=$_apiKey&limit=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() =>
            _searchResults = List<Map<String, dynamic>>.from(data['results']));
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : DateTimeRange(
              start: DateTime.now(),
              end: DateTime.now().add(Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }

  Future<void> generateItinerary() async {
    const String apiKey =
        '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';
    const String endpoint = 'https://api.groq.com/openai/v1/chat/completions';

    try {
      setState(() {
        _isLoading = true;
      });

      final payload = {
        "messages": [
          {
            "role": "user",
            "content": """
              Plan a ${_travelType ?? ''} travel itinerary for ${_destinationController.text}
              from ${DateFormat.yMMMd().format(_selectedStartDate!)} to ${DateFormat.yMMMd().format(_selectedEndDate!)} 
              with a ${_costPreference ?? ''} budget inform local rules/alerts/scams if any.use INR/USD not symbols.
              """
          }
        ],
        "model": "llama-3.2-11b-vision-preview",
        "temperature": 1,
        "max_tokens": 1024,
        "top_p": 1,
        "stream": false,
        "stop": null,
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _itinerary = data['choices'][0]['message']['content'];
        });
      } else {
        setState(() {
          _itinerary =
              "Failed to generate itinerary. HTTP Error: ${response.statusCode}";
        });
      }
    } catch (error) {
      setState(() {
        _itinerary =
            "An error occurred while generating the itinerary. Error: $error";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF3B82F6);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const cardBackgroundColor = Color(0xFFFFFFFF);
  static const textColor = Color(0xFF1E293B);
  static const borderColor = Color(0xFFE2E8F0);

  Widget _buildInputField({
    required Widget child,
    required String label,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Safe Tour - Trip Planner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildInputField(
                        label: 'Where do you want to go?',
                        icon: Icons.location_on,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                hintText: 'Enter destination',
                                prefixIcon:
                                    Icon(Icons.search, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              onChanged: _handleSearch,
                            ),
                            if (_searchResults.isNotEmpty)
                              Container(
                                color: Colors.white,
                                child: Column(
                                  children: _searchResults.map((result) {
                                    return ListTile(
                                      title: Text(result['formatted']),
                                      onTap: () {
                                        _destinationController.text =
                                            result['formatted'];
                                        setState(() {
                                          _searchResults = [];
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Select Date Range',
                        icon: Icons.calendar_today,
                        child: InkWell(
                          onTap: _pickDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: borderColor,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              color: Colors.grey[100],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedStartDate != null &&
                                            _selectedEndDate != null
                                        ? '${DateFormat.yMMMd().format(_selectedStartDate!)} - ${DateFormat.yMMMd().format(_selectedEndDate!)}'
                                        : 'Select date range',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Travel Type',
                        icon: Icons.person,
                        child: DropdownButtonFormField<String>(
                          value: _travelType,
                          onChanged: (newValue) {
                            setState(() {
                              _travelType = newValue;
                            });
                          },
                          items: _travelTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            hintText: 'Select travel type',
                            prefixIcon: Icon(Icons.group, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: 'Cost Preference',
                        icon: Icons.monetization_on,
                        child: DropdownButtonFormField<String>(
                          value: _costPreference,
                          onChanged: (newValue) {
                            setState(() {
                              _costPreference = newValue;
                            });
                          },
                          items: _costPreferences.map((preference) {
                            return DropdownMenuItem<String>(
                              value: preference,
                              child: Text(preference),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            hintText: 'Select cost preference',
                            prefixIcon: Icon(Icons.monetization_on,
                                color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 14,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: generateItinerary,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: primaryColor,
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Generating...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Generate Itinerary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _itinerary.isNotEmpty
                  ? Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: MarkdownBody(
                          data: _itinerary,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
