import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:meteo/screens/navigation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dbservices.dart';
import 'registerpage.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final DBService _dbService = DBService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final Color _darkBlue = const Color(0xFF132856); 
  final Color _accentBlue = const Color(0xFF1BC2EE); 

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  void _login() async {
    if (emailC.text.isEmpty || passC.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi semua kolom!'),
          backgroundColor: Color(0xFFF6A70A),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String hashed = sha256.convert(utf8.encode(passC.text)).toString();
    UserModel? user = await _dbService.loginUser(emailC.text.trim(), hashed);

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('currentUserId', user.id ?? 0); 
      await prefs.setString('currentUsername', user.username);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil!'),
          backgroundColor: Color(0xFF2B8636),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Navigation()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email atau kata sandi tidak valid!'),
          backgroundColor: Color(0xFFD24228),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selamat Datang Kembali 🌦️", 
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _darkBlue, 
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Login untuk melihat informasi cuaca terkini!", 
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),

            Text(
              "Email",
              style: TextStyle(color: _darkBlue, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailC,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.blue.shade50, 
                hintText: "nama@email.com",
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Password",
              style: TextStyle(color: _darkBlue, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passC,
              obscureText: !_isPasswordVisible,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.blue.shade50,
                hintText: "********",
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[600], 
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Login",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: Text(
                  "Belum punya akun? Daftar di sini",
                  style: TextStyle(
                    color: _darkBlue, 
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}