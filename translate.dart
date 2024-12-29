import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class TranslatePage extends StatefulWidget {
  @override
  _TranslatePageState createState() => _TranslatePageState();
}

class _TranslatePageState extends State<TranslatePage>
    with SingleTickerProviderStateMixin {
  final translator = GoogleTranslator();
  final flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();

  stt.SpeechToText _speechToText = stt.SpeechToText();

  String _inputText = "";
  String _translatedText = "";
  String _targetLanguage = "es"; // Default to Spanish
  bool _isListening = false;
  bool _isLoading = false;

  AnimationController? _controller;

  // Supported language codes
  final Map<String, String> _languages = {
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Hindi': 'hi',
    'Chinese': 'zh',
    'Arabic': 'ar',
    'Russian': 'ru',
    'English': 'en',
    'Tamil': 'ta',
    'Telugu': 'te',
  };

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Keeps the background transparent
        elevation: 0,
        title: Text(
          "Voice & Text Translator",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Set title text color to white
          ),
        ),
        iconTheme: IconThemeData(
            color: Colors.white), // Change navigation button color to white
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.grey[900]!],
          ),
        ),
        child: FadeIn(
          duration: Duration(milliseconds: 800),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Input Text Field
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(10),
                    child: TextField(
                      controller: _textController, // Attach the controller
                      onChanged: (value) {
                        setState(() {
                          _inputText = value; // Manually update input text
                        });
                      },
                      style: TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter text to translate...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Language Dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Translate to: ",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        dropdownColor: Colors.grey[900],
                        value: _targetLanguage,
                        style: TextStyle(color: Colors.white),
                        items: _languages.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.value,
                            child: Text(entry.key),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _targetLanguage = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Voice Input with Animation
                      GestureDetector(
                        onTap: _listen,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.redAccent
                                : Colors.blueAccent, // Toggle color
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(20),
                          child: Icon(
                            _isListening
                                ? Icons.stop
                                : Icons.mic, // Toggle icon
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      SizedBox(width: 20),

                      // Translate Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent[700],
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        icon: Icon(Icons.translate, color: Colors.white),
                        label: Text("Translate",
                            style: TextStyle(color: Colors.white)),
                        onPressed: _translateText,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Loading Indicator
                  if (_isLoading)
                    CircularProgressIndicator(
                      color: Colors.greenAccent,
                    ),

                  // Translated Text Display with Speak Button
                  if (_translatedText.isNotEmpty)
                    BounceInUp(
                      duration: Duration(milliseconds: 800),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _translatedText,
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            IconButton(
                              onPressed: () => _speak(_translatedText),
                              icon: Icon(Icons.volume_up,
                                  color: Colors.greenAccent, size: 30),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Function to Translate Text
  void _translateText() async {
    if (_inputText.isEmpty) {
      _showError("Please enter text to translate.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final translation =
          await translator.translate(_inputText, to: _targetLanguage);
      setState(() {
        _translatedText = translation.text;
      });
      _speak(translation.text);
    } catch (e) {
      _showError("Translation failed. Try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Function to Speak Translated Text
  void _speak(String text) async {
    try {
      await flutterTts.setLanguage(_targetLanguage);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVoice({"name": "Karen", "locale": "en-US"});
      await flutterTts.speak(text);
    } catch (e) {
      _showError("Failed to speak the text.");
    }
  }

  // Voice Input with Animation
  void _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _controller?.forward(); // Start animation
        });
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              String newText = result.recognizedWords;
              if (!_inputText.endsWith(newText)) {
                // Append only if it's not already appended
                _inputText = (_inputText + " " + newText).trim();
                _textController.text = _inputText;

                // Move cursor to end of the text
                _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length),
                );
              }
            });
          },
          listenFor: Duration(
              seconds: 10), // Set timeout to stop listening automatically
        );
      } else {
        _showError("Speech recognition is not available.");
      }
    } else {
      setState(() {
        _isListening = false;
        _controller?.reset(); // Stop animation
      });
      _speechToText.stop();
    }
  }

  // Show Error Message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
