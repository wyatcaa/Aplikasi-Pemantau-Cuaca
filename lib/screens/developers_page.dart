import 'package:flutter/material.dart';

class AboutDeveloperPage extends StatelessWidget {
  const AboutDeveloperPage({Key? key}) : super(key: key);

  static const Color kBgTop = Color(0xFF6BAAFC);
  static const Color kBgBottom = Color(0xFF3F82E8);
  static const Color kCardBg = Color(0x25FFFFFF);
  static const Color kTextWhite = Colors.white;
  static const Color kTextGrey = Color(0xFFD4E4FF);
  static const Color kAccentBlue = Color(0xFFB3D4FF);
  static const Color kAccentYellow = Color(0xFFFFD56F);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBgTop, kBgBottom],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "Tentang Developer",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: kTextWhite,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDevCard(
                photoPath: 'assets/images/dev1.jpg',
                name: 'Wulan Cahya Ningrum',
                nim: '124230037',
              ),
              const SizedBox(height: 16),
              _buildDevCard(
                photoPath: 'assets/images/dev2.jpg',
                name: 'Fatma Triana',
                nim: '124230039',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevCard({
    required String photoPath,
    required String name,
    required String nim,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(photoPath),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: kTextWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nim,
                  style: const TextStyle(
                    color: kTextGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
