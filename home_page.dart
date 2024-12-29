import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'TripPlanner.dart';
import 'explore.dart';
import 'report_scams.dart';
import 'translate.dart';
import 'editProf.dart';
import 'travel_expense.dart';
import 'dart:math';
import 'login_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(const HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tour App',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orangeAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F5F7),
      ),
      home: const HomeScreen(),
      routes: {
        '/editProf': (context) => const EditProfileScreen(),
        '/login_page': (context) => const LoginPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/editProf') {
          return MaterialPageRoute(
              builder: (context) => const EditProfileScreen());
        }
        return null;
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 10 * _controller.value),
              child: const Text(
                'Travel Companion',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'OliveVillage',
                  letterSpacing: 1.5,
                ),
              ),
            );
          },
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.7),
                      Colors.purple.withOpacity(0.7),
                      Colors.pink.withOpacity(0.7),
                    ],
                    stops: [
                      0.0,
                      0.5 + 0.5 * sin(_controller.value * 2 * pi),
                      1.0,
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcATop,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              children: <Widget>[
                GreetingWithImageSlider(),
                const SizedBox(height: 30.0),
                LocationAlertsWeather(),
                const SizedBox(height: 30.0),
                ExploreFeaturesCarousel(),
                const SizedBox(height: 30.0),
                DestinationCarousel(),
                const SizedBox(height: 30.0),
                Footer(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: Colors.white.withOpacity(0.2),
        child: SizedBox(
          height: 50, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentTab = 0;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                      MainAxisAlignment.center, 
                  children: [
                    Icon(
                      Icons.search,
                      size: 30.0,
                      color: _currentTab == 0 ? Colors.black : Colors.black,
                    ),
                    Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentTab == 0 ? Colors.black : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTapDown: (TapDownDetails details) {
                  _showProfileMenu(context, details.globalPosition);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment:
                      MainAxisAlignment.center, 
                  children: [
                    Icon(
                      Icons.person,
                      size: 30.0,
                      color: _currentTab == 1 ? Colors.black : Colors.black,
                    ),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentTab == 1 ? Colors.black : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showProfileMenu(BuildContext context, Offset position) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy + 30,
      ),
      items: [
        const PopupMenuItem(
          value: 'Profile Info',
          child: Text('Profile Info'),
        ),
        const PopupMenuItem(
          value: 'Logout',
          child: Text('Logout'),
        ),
      ],
    );

    if (selected == 'Profile Info') {
      Navigator.pushNamed(context,
          '/editProf'); 
    } else if (selected == 'Logout') {
      _logout(context);
    }
  }


  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); 

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login_page', 
        (Route<dynamic> route) =>
            false, 
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
        ),
      );
    }
  }
}

class GreetingWithImageSlider extends StatefulWidget {
  @override
  _GreetingWithImageSliderState createState() =>
      _GreetingWithImageSliderState();
}

class _GreetingWithImageSliderState extends State<GreetingWithImageSlider> {
  final List<String> images = [
    'assets/carousel/picture1(1).jpg',
    'assets/carousel/picture1(2).jpg',
    'assets/carousel/picture1(3).jpg',
  ];

  String firstName = 'User'; // Default first name
  bool isLoading = true; // Loading indicator for fetching user data

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the widget initializes
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
            isLoading = false;
          });
        } else {
          print("No user data found for email: ${user.email}");
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10), // Increased gap at the top
        Text(
          isLoading
              ? 'Loading...' // Display loading text until the user data is fetched
              : 'Hi, $firstName! Welcome back. Where are we going today?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 50),
        CarouselSlider(
          items: images
              .map(
                (image) => ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width * 0.69,
                  ),
                ),
              )
              .toList(),
          options: CarouselOptions(
            height: 340.0,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            enableInfiniteScroll: true,
          ),
        ),
        SizedBox(height: 130.0),
      ],
    );
  }
}

class LocationAlertsWeather extends StatefulWidget {
  @override
  _LocationAlertsWeatherState createState() => _LocationAlertsWeatherState();
}

class _LocationAlertsWeatherState extends State<LocationAlertsWeather>
    with SingleTickerProviderStateMixin {
  String city = 'Fetching...';
  String state = '';
  String district = '';
  String weatherDescription = 'Loading...';
  IconData weatherIcon =
      Icons.not_listed_location_sharp; 
  Color iconColor = Colors.grey; 
  bool isLoading = true;
  String alertMessage = "No alerts available";
  bool isExpanded = false; 
  final String pythonApiUrl =
      'http://68.178.238.26:8000/scrape'; 

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        isLoading = true;
      });

      await _fetchLocationAndWeather();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Initialization error: $e");
      setState(() {
        isLoading = false;
        alertMessage = "Error initializing data.";
      });
    }
  }

  Future<void> _fetchLocationAndWeather() async {
    try {
      Position position = await _getCurrentLocation();
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      await _fetchWeather(position.latitude, position.longitude);
    } catch (e) {
      print("Error in location or weather fetching: $e");
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are disabled.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception("Location permission denied.");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied.");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    const nominatimURL = "https://nominatim.openstreetmap.org/reverse";
    final url =
        Uri.parse('$nominatimURL?format=json&lat=$latitude&lon=$longitude');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          city = data['address']['city'] ??
              data['address']['town'] ??
              data['address']['village'] ??
              'Unknown';
          district = " " + (data['address']['county'] ?? '');
          state = " " + (data['address']['state'] ?? '');
        });

  
        await _fetchAlerts(city + district + state);
      } else {
        throw Exception("Failed to fetch address from Nominatim.");
      }
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    final apiKey = '2c46c3bba90211c0e18241f31dd52c79'; 
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          weatherDescription = data['weather'][0]['description'];
          String iconCode = data['weather'][0]['icon'];
          weatherIcon = _getWeatherIcon(iconCode);
          iconColor = _getIconColor(iconCode);
        });
      } else {
        throw Exception("Failed to fetch weather.");
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
  }

  Future<void> _fetchAlerts(String cityName) async {
    try {
      final response = await http.post(
        Uri.parse(pythonApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'city': cityName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          alertMessage = data['content'] ?? "No alerts available.";
        });
      } else {
        throw Exception("Failed to fetch alerts: ${response.body}");
      }
    } catch (e) {
      print("Error fetching alerts: $e");
      setState(() {
        alertMessage = 'Unable to fetch alerts.';
      });
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny; // Clear sky
      case '02d':
        return Icons.cloud_queue; // Few clouds
      case '03d':
        return Icons.cloud; // Scattered clouds
      case '09d':
        return Icons.grain; // Shower rain
      case '10d':
        return Icons.beach_access; // Rain
      case '11d':
        return Icons.flash_on; // Thunderstorm
      case '13d':
        return Icons.ac_unit; // Snow
      case '50d':
        return Icons.blur_on; // Mist
      default:
        return Icons.wb_cloudy; // Default
    }
  }

  Color _getIconColor(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Colors.orange; // Clear sky
      case '02d':
        return Colors.lightBlueAccent; // Few clouds
      case '03d':
        return Colors.grey; // Scattered clouds
      case '09d':
        return Colors.blueGrey; // Shower rain
      case '10d':
        return Colors.blue; // Rain
      case '11d':
        return Colors.yellowAccent; // Thunderstorm
      case '13d':
        return Colors.white; // Snow
      case '50d':
        return Colors.greenAccent; // Mist
      default:
        return Colors.grey; // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Box 1: Location and Weather
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$city $district $state',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Icon(weatherIcon, size: 40, color: iconColor),
                      SizedBox(height: 8),
                      Text(
                        weatherDescription.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16), 
              // Box 2: Travel Alerts
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  child: AnimatedSize(
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '🚨 Travel Alerts !',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            isExpanded
                                ? alertMessage
                                : '${alertMessage.substring(0, alertMessage.length > 50 ? 50 : alertMessage.length)}...',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}

class ExploreFeaturesCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> features = [
    {'icon': Icons.public, 'label': 'Explore', 'route': 'explore'},
    {'icon': Icons.map, 'label': 'Trip Planner', 'route': 'trip_planner'},
    {'icon': Icons.report, 'label': 'Report Scams', 'route': 'report_scams'},
    {
      'icon': Icons.monetization_on,
      'label': 'Travel Expense',
      'route': 'travel_expense'
    },
    {'icon': Icons.translate, 'label': 'Translate', 'route': 'translate'},
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 130.0),
          FractionallySizedBox(
            alignment: Alignment.center,
            widthFactor: 0.8,
            child: SizedBox(
              height: 160.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: features.length,
                itemBuilder: (BuildContext context, int index) {
                  return HoverAnimatedBox(
                    icon: features[index]['icon'],
                    label: features[index]['label'],
                    onTap: () {

                      String route = features[index]['route'];
                      switch (route) {
                        case 'explore':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ExplorePage()),
                          );
                          break;
                        case 'trip_planner':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TripPlanner()),
                          );
                          break;
                        case 'report_scams':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ScamReportPage()),
                          );
                          break;
                        case 'travel_expense':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TravelExpensePage()),
                          );
                          break;
                        case 'translate':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TranslatePage()),
                          );
                          break;
                      }
                    },
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 130.0),
        ],
      ),
    );
  }
}


class HoverAnimatedBox extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HoverAnimatedBox({
    required this.icon,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  _HoverAnimatedBoxState createState() => _HoverAnimatedBoxState();
}

class _HoverAnimatedBoxState extends State<HoverAnimatedBox> {
  bool _isHovered = false;

  @override
Widget build(BuildContext context) {
  return MouseRegion(
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: _isHovered ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (value * 0.1), 
            child: Transform.rotate(
              angle: value * 0.785, 
              child: Container(
                width: 160.0,
                height: 160.0,
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10.0 + (value * 5.0),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: -(value * 0.785), 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        size: 45.0,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
}
class DestinationCarousel extends StatelessWidget {
  final List<Map<String, String>> destinations = [
    {'image': 'assets/carousel/picture1(4).jpg', 'name': 'London, UK'},
    {'image': 'assets/carousel/picture1(5).jpg', 'name': 'Sydney, Australia'},
    {'image': 'assets/carousel/picture1(6).jpg', 'name': 'Berlin, Germany'},
    {'image': 'assets/carousel/picture1(4).jpg', 'name': 'Delhi, India'},
    {'image': 'assets/carousel/picture1(5).jpg', 'name': 'Mumbai, India'},
    {'image': 'assets/carousel/picture1(6).jpg', 'name': 'Toronto, Canada'},
    {'image': 'assets/carousel/picture1(4).jpg', 'name': 'Bengaluru, India'},
    {'image': 'assets/carousel/picture1(5).jpg', 'name': 'Kolkata, India'},
    {'image': 'assets/carousel/picture1(6).jpg', 'name': 'Rio de Janeiro, Brazil'}
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 250.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: destinations.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TravelPlannerPage(
                      cityName: destinations[index]['name']!,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(10.0),
                width: 300.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: const Offset(0, 2),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Image.asset(
                        destinations[index]['image']!,
                        height: 250.0,
                        width: 300.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(15.0),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20.0),
                            bottomRight: Radius.circular(20.0),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          destinations[index]['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TravelPlannerPage extends StatefulWidget {
  final String cityName;

  const TravelPlannerPage({Key? key, required this.cityName}) : super(key: key);

  @override
  _TravelPlannerPageState createState() => _TravelPlannerPageState();
}

class _TravelPlannerPageState extends State<TravelPlannerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final cityImages = {
      'London, UK': 'assets/carousel/picture1(4).jpg',
      'Sydney, Australia': 'assets/carousel/picture1(5).jpg',
      'Berlin, Germany': 'assets/carousel/picture1(6).jpg',
      'Delhi, India': 'assets/carousel/picture1(4).jpg',
      'Mumbai, India': 'assets/carousel/picture1(5).jpg',
      'Toronto, Canada': 'assets/carousel/picture1(6).jpg',
      'Bengaluru, India': 'assets/carousel/picture1(4).jpg',
      'Kolkata, India': 'assets/carousel/picture1(5).jpg',
      'Rio de Janeiro, Brazil': 'assets/carousel/picture1(6).jpg',
    };


    final imagePath = cityImages[widget.cityName] ?? 'assets/default_image.jpg';

    return Scaffold(
      appBar: AppBar(title: const Text('Popular Destinations')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.asset(
                  imagePath,
                  height: 200.0,
                  width: 300.0,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Great Choice! ${widget.cityName} it is this time! Plan your trip here.',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripPlanner(
                      locationData: {
                        'destination': widget.cityName,
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Start Planning'),
            ),
          ],
        ),
      ),
    );
  }
}


class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: const [
          SizedBox(height: 60.0),
          Text(
            'Made by : Manisha, Antonio Roger, Akshith',
            style: TextStyle(fontSize: 19.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.0),
          Text('Email: asafetyguide.com'),
          SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email),
              SizedBox(width: 10.0),
              Icon(Icons.facebook),
              SizedBox(width: 10.0),
              Icon(Icons.icecream_outlined),
            ],
          ),
          SizedBox(height: 20.0),
        ],
      ),
    );
  }
}
