import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Create an Account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text("To Get Started!", style: TextStyle(fontSize: 24)),
            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Stack(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(Icons.visibility_off, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: Text("Sign Up")),
            TextButton(onPressed: () {}, 
            child: Text(
              "Already have an account? Login here.", 
              style: TextStyle(
                fontSize: 12,
                // decoration: TextDecoration.underline,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
