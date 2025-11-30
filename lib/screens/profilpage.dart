import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meteo/screens/developers_page.dart';
import '../services/dbservices.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loginPage.dart';

const Color kBgTop = Color(0xFF6BAAFC);
const Color kBgBottom = Color(0xFF3F82E8);
const Color kCardBg = Color(0x25FFFFFF);
const Color kTextWhite = Colors.white;
const Color kTextGrey = Color(0xFFD4E4FF);
const Color kAccentBlue = Color(0xFFB3D4FF);
const Color kAccentYellow = Color(0xFFFFD56F);

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();

  UserModel? user;
  String? photoPath;
  bool loading = true;

  final List<String> units = ["c", "f", "k"];
  String selectedUnit = "c";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    user = await DBService().getUser();
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      nameC.text = user!.username;
      emailC.text = user!.email;
      passC.text = user!.password;
      photoPath = user!.photoPath;
      selectedUnit = prefs.getString('tempUnit') ?? user!.tempUnit.toLowerCase();
    }

    setState(() => loading = false);
  }

  Future<void> _saveField({String? username, String? email, String? password}) async {
    if (user == null) return;

    user = UserModel(
      id: user!.id,
      username: username ?? user!.username,
      email: email ?? user!.email,
      password: password ?? user!.password,
      tempUnit: selectedUnit,
      photoPath: photoPath,
    );

    await DBService().updateUser(user!);
    setState(() {});
  }

  Future<void> _saveUnit(String unit) async {
    selectedUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tempUnit', unit);

    if (user != null) {
      user = UserModel(
        id: user!.id,
        username: user!.username,
        email: user!.email,
        password: user!.password,
        tempUnit: unit,
        photoPath: photoPath,
      );
      await DBService().updateUser(user!);
    }

    setState(() {});
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);

    if (picked == null) return;

    setState(() => photoPath = picked.path);

    if (user != null) {
      user = UserModel(
        id: user!.id,
        username: user!.username,
        email: user!.email,
        password: user!.password,
        tempUnit: user!.tempUnit,
        photoPath: photoPath,
      );
      await DBService().updateUser(user!);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo, color: kBgTop),
            title: const Text("Pilih dari Galeri"),
            onTap: () {
              Navigator.pop(context);
              _pickPhoto(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt, color: kBgTop),
            title: const Text("Ambil Foto Kamera"),
            onTap: () {
              Navigator.pop(context);
              _pickPhoto(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showEditDialog({
    required String label,
    required TextEditingController controller,
    required Future<void> Function() onSave,
    bool obscureText = false,
  }) async {
    final tempController = TextEditingController(text: controller.text);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kBgTop.withOpacity(0.9),
          title: Text('Ubah $label', style: const TextStyle(color: kTextWhite)),
          content: TextField(
            controller: tempController,
            obscureText: obscureText,
            style: const TextStyle(color: kTextWhite),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: kTextGrey),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: kTextWhite.withOpacity(0.5))),
              focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: kAccentYellow)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: kAccentYellow)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentYellow, foregroundColor: Colors.black),
              child: const Text('Simpan'),
              onPressed: () async {
                controller.text = tempController.text.trim();
                await onSave();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required Future<void> Function() onSave,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: true, 
      obscureText: obscureText,
      obscuringCharacter: '•',
      style: const TextStyle(color: kTextWhite, fontWeight: FontWeight.w600),
      keyboardType: keyboardType,
      onTap: () => _showEditDialog(
        label: label,
        controller: controller,
        onSave: onSave,
        obscureText: obscureText,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextGrey),
        filled: true,
        fillColor: kCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.edit, color: kAccentYellow),
          onPressed: () => _showEditDialog(
            label: label,
            controller: controller,
            onSave: onSave,
            obscureText: obscureText,
          ),
        ),
      ),
    );
  }

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
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "Profile",
            style: TextStyle(
              color: kTextWhite,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator(color: kAccentYellow))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _showPhotoOptions,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: kTextWhite.withOpacity(0.1),
                              backgroundImage:
                                  photoPath != null ? FileImage(File(photoPath!)) : null,
                              child: photoPath == null
                                  ? Icon(Icons.person, size: 60, color: kTextGrey)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _showPhotoOptions,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kBgTop,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kTextWhite, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildEditableField(
                      label: "Nama Pengguna",
                      controller: nameC,
                      onSave: () => _saveField(username: nameC.text.trim()),
                    ),
                    const SizedBox(height: 12),

                    _buildEditableField(
                      label: "Email",
                      controller: emailC,
                      onSave: () => _saveField(email: emailC.text.trim()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    _buildEditableField(
                      label: "Password",
                      controller: passC,
                      obscureText: true,
                      onSave: () => _saveField(password: passC.text.trim()),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Pengaturan Suhu",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextWhite),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      iconEnabledColor: kTextWhite,
                      style: const TextStyle(color: kTextWhite, fontSize: 16),
                      dropdownColor: kBgTop,
                      decoration: InputDecoration(
                        labelText: "Satuan Suhu",
                        labelStyle: const TextStyle(color: kTextGrey),
                        filled: true,
                        fillColor: kCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: "c",
                            child: Text("Celcius (°C)",
                                style: const TextStyle(color: kTextWhite))),
                        DropdownMenuItem(
                            value: "f",
                            child: Text("Fahrenheit (°F)",
                                style: const TextStyle(color: kTextWhite))),
                        DropdownMenuItem(
                            value: "k",
                            child: Text("Kelvin (K)",
                                style: const TextStyle(color: kTextWhite))),
                      ],
                      onChanged: (v) {
                        if (v != null) _saveUnit(v);
                      },
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Tentang Aplikasi",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextWhite),
                    ),

                    ListTile(
                      leading: const Icon(Icons.info_outline, color: kAccentYellow),
                      title: const Text("Versi Aplikasi",
                          style: TextStyle(color: kTextWhite)),
                      subtitle:
                          const Text("1.0.0", style: TextStyle(color: kTextGrey)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code, color: kAccentYellow),
                      title: const Text("Tentang Developer",
                          style: TextStyle(color: kTextWhite)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: kTextWhite),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutDeveloperPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: kTextWhite,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }
}
