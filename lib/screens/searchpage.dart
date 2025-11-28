import 'package:flutter/material.dart';
import 'package:meteo/screens/detailpage.dart';
import '../models/location_model.dart';
import '../widgets/search_widget.dart';
import '../services/dbservices.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DBService _dbService = DBService(); 
  LocationModel? _selected;
  List<LocationModel> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory(); 
  }

  void _loadHistory() async {
    final history = await _dbService.getLocations();
    if (mounted) {
      setState(() {
        _history = history;
      });
    }
  }

void _onSelect(LocationModel loc) async {
  await _dbService.saveLocation(loc);
  _loadHistory(); 
  setState(() => _selected = loc);
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailPage(loc: loc),
    ),
  );
  if (mounted) {
    setState(() {
      _selected = null; 
    });
  }
}

  void _clearHistory() async {
    await _dbService.clearAllHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pencarian', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF0077B6),
          foregroundColor: Colors.white,
        ),

        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                SearchLocationWidget(onSelect: _onSelect),
                
                const SizedBox(height: 24),
                
                if (_history.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Riwayat Pencarian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearHistory, 
                        child: const Text('Hapus Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _history.map((loc) {
                      return Card(
                        color:Color(0xFF58A0C8).withOpacity(0.9),
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Colors.white),
                          title: Text('${loc.name}, ${loc.country}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('lat: ${loc.latitude}, lon: ${loc.longitude}', style: TextStyle(color: Colors.white)),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            _onSelect(loc); 
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (_selected != null) ...[
                  const Text(
                    'Lokasi Terpilih',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Card(
                    color:Color(0xFF58A0C8).withOpacity(0.9),
                    elevation: 2,
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.white),
                      title: Text('${_selected!.name}, ${_selected!.country}'),
                      subtitle: Text(
                        'lat: ${_selected!.latitude}, '
                        'lon: ${_selected!.longitude}\n'
                        'tz: ${_selected!.timezone}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
