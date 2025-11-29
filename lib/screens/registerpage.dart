import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/dbservices.dart';
import '../models/user_model.dart';
import 'loginpage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController usernameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController confirmPassC = TextEditingController();
  final DBService _dbService = DBService();
  
  bool _isPassVisible = false;
  bool _isConfirmPassVisible = false;

  final Color _darkBlue = const Color(0xFF132856); 

  @override
  void dispose() {
    usernameC.dispose();
    emailC.dispose();
    passC.dispose();
    confirmPassC.dispose();
    super.dispose();
  }

  void _register() async {
    if (passC.text != confirmPassC.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi tidak cocok!'),
          backgroundColor: Color(0xFFD24228), 
        ),
      );
      return;
    }

    if (usernameC.text.isEmpty || emailC.text.isEmpty || passC.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom harus diisi!'), 
          backgroundColor: Color(0xFFF6A70A), 
        ),
      );
      return;
    }

    String hashed = sha256.convert(utf8.encode(passC.text)).toString();

    UserModel user = UserModel(
      username: usernameC.text.trim(),
      email: emailC.text.trim(),
      password: hashed,
      photoPath: null,
      tempUnit: "C", 
    );

    await _dbService.registerUser(user);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Akun berhasil dibuat! Silakan masuk.'), 
        backgroundColor: Color(0xFF2B8636), 
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Buat Akun Baru 🌦️", 
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Gabung untuk melihat informasi cuaca akurat!", 
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14), 
            ),
            const SizedBox(height: 40),
            
            Text("Username",
                style: TextStyle(fontSize: 14, color: _darkBlue)),  
            const SizedBox(height: 8),
            TextField(
              controller: usernameC,
              style: TextStyle(color: _darkBlue), 
              decoration: InputDecoration(
                hintText: "Nama pengguna Anda", 
                hintStyle: TextStyle(color: Colors.grey.shade400), 
                filled: true,
                fillColor: Colors.blue.shade50, 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            Text("Email",
                style: TextStyle(fontSize: 14, color: _darkBlue)),
            const SizedBox(height: 8),
            TextField(
              controller: emailC,
              style: TextStyle(color: _darkBlue),
              decoration: InputDecoration(
                hintText: "nama@email.com", 
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text("Kata Sandi",
                style: TextStyle(fontSize: 14, color: _darkBlue)),  
            const SizedBox(height: 8),
            TextField(
              controller: passC,
              obscureText: !_isPassVisible, 
              style: TextStyle(color: _darkBlue),
              decoration: InputDecoration(
                hintText: "**********",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPassVisible ? Icons.visibility : Icons.visibility_off,
                    color: _darkBlue, 
                  ),
                  onPressed: () {
                    setState(() {
                      _isPassVisible = !_isPassVisible;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text("Konfirmasi Kata Sandi",
                style: TextStyle(fontSize: 14, color: _darkBlue)),  
            const SizedBox(height: 8),
            TextField(
              controller: confirmPassC,
              obscureText: !_isConfirmPassVisible, 
              style: TextStyle(color: _darkBlue),
              decoration: InputDecoration(
                hintText: "**********",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPassVisible ? Icons.visibility : Icons.visibility_off,
                    color: _darkBlue,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPassVisible = !_isConfirmPassVisible;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BC2EE), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Daftar",  
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
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  "Sudah punya akun? Masuk di sini",  
                  style: TextStyle(color: _darkBlue, fontSize: 14, fontWeight: FontWeight.w500), 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}