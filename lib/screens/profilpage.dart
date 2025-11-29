import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/dbservices.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // dropdown suhu
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

  // -----------------------
  // SAVE INDIVIDUAL FIELD
  // -----------------------
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
    setState(() {}); // refresh UI
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

  // -----------------------
  // PICK PHOTO
  // -----------------------
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
            leading: const Icon(Icons.photo),
            title: const Text("Pilih dari Galeri"),
            onTap: () {
              Navigator.pop(context);
              _pickPhoto(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
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
    await prefs.clear(); // Hapus session / login info
    // Tambahkan navigasi ke login page
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // -----------------------
  // UI
  // -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil & Pengaturan")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FOTO PROFIL
                  Center(
                    child: GestureDetector(
                      onTap: _showPhotoOptions,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            photoPath != null ? FileImage(File(photoPath!)) : null,
                        child: photoPath == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // USERNAME
                  _buildEditableField(
                    label: "Nama",
                    controller: nameC,
                    onSave: () => _saveField(username: nameC.text.trim()),
                  ),
                  const SizedBox(height: 12),

                  // EMAIL
                  _buildEditableField(
                    label: "Email",
                    controller: emailC,
                    onSave: () => _saveField(email: emailC.text.trim()),
                  ),
                  const SizedBox(height: 12),

                  // PASSWORD
                  _buildEditableField(
                    label: "Password",
                    controller: passC,
                    obscureText: true,
                    onSave: () => _saveField(password: passC.text.trim()),
                  ),
                  const SizedBox(height: 20),

                  // -----------------------
                  // DROPDOWN SUHU
                  // -----------------------
                  const Text("Pengaturan Suhu",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(
                      labelText: "Satuan Suhu",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "c", child: Text("Celcius (°C)")),
                      DropdownMenuItem(value: "f", child: Text("Fahrenheit (°F)")),
                      DropdownMenuItem(value: "k", child: Text("Kelvin (K)")),
                    ],
                    onChanged: (v) {
                      if (v != null) _saveUnit(v);
                    },
                  ),
                  const SizedBox(height: 30),

                  // -----------------------
                  // MENU TENTANG DEVELOPER
                  // -----------------------
                  const Text("Tentang Aplikasi",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("Versi Aplikasi"),
                    subtitle: const Text("1.0.0"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text("Hubungi Developer"),
                    subtitle: const Text("seascopecsupport@email.com"),
                  ),
                  const SizedBox(height: 20),

                  // -----------------------
                  // LOGOUT
                  // -----------------------
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSave,
    bool obscureText = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSave,
          color: Colors.green,
        ),
      ],
    );
  }
}
