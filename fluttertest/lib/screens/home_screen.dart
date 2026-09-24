import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Centers horizontally

            children: [
              Column(
                children: [
                  Text(
                    "Jarvay",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 50),
                  Image.asset(
                    'assets/images/agnostic_crab.png',
                    width: 300,
                    height: 300,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
