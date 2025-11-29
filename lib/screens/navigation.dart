import 'package:flutter/material.dart';
import 'package:meteo/screens/homepage.dart';
import 'package:meteo/screens/savedpage.dart';
import 'package:meteo/screens/searchpage.dart';
import 'package:meteo/screens/profilpage.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const SearchScreen(),
    const SavedPage(),
    const ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // --- TAMBAHKAN PROPERTI INI ---
        type: BottomNavigationBarType.fixed, // Wajib biar gak putih/hilang
        backgroundColor: Colors.white,       // Warna latar belakang navbar
        selectedItemColor: const Color(0xFF6BAAFC), // Warna ikon aktif (Biru Langit)
        unselectedItemColor: Colors.grey,    // Warna ikon tidak aktif
        showUnselectedLabels: true,          // Tampilkan label meski tidak dipilih
        // ------------------------------
        
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Saved"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

