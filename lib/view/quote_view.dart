import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MotivationalQuotePage extends StatefulWidget {
  const MotivationalQuotePage({Key? key}) : super(key: key);

  @override
  _MotivationalQuotePageState createState() => _MotivationalQuotePageState();
}

class _MotivationalQuotePageState extends State<MotivationalQuotePage> {
  late String currentQuote = 'Loading quote...';

  @override
  void initState() {
    super.initState();
    fetchQuote();
  }

  Future<void> fetchQuote() async {
    final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));

    if (response.statusCode == 200) {
      final quoteData = json.decode(response.body);
      final String quote = quoteData[0]['q'] + ' - ' + quoteData[0]['a'];
      setState(() {
        currentQuote = quote;
      });
    } else {
      setState(() {
        currentQuote = 'Failed to load quote';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote of the Day'),
          backgroundColor: const Color.fromARGB(255, 31, 86, 111),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade200,
      body: Stack(
        children: [
          Positioned(
            top: 90,
            left: -32,
            child: Container(
              width: 170,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                color: Color.fromARGB(255, 31, 86, 111),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 32,
            child: Container(
              width: 60,
              height: 190,
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                color: Color.fromARGB(255, 31, 86, 111),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 32,
            child: Container(
              width: 60,
              height: 190,
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                color: Color.fromARGB(255, 31, 86, 111),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            right: -32,
            child: Container(
              width: 170,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                color: Color.fromARGB(255, 31, 86, 111),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 50,
                        ),
                      ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                child: Text(
                  currentQuote ?? 'Loading quote...',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ]
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 31, 86, 111),
        onPressed: fetchQuote,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
