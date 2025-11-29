import 'package:flutter/material.dart';
import '../services/geocodingservices.dart';
import '../models/location_model.dart';

class SearchLocationWidget extends StatefulWidget {
  final Function(LocationModel) onSelect;
  const SearchLocationWidget({super.key, required this.onSelect});

  @override
  State<SearchLocationWidget> createState() => _SearchLocationWidgetState();
}

class _SearchLocationWidgetState extends State<SearchLocationWidget> {
  final _ctrl = TextEditingController();
  final GeocodingService _service = GeocodingService();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_clearIfEmpty);
  }

  void _clearIfEmpty() {
    if (_ctrl.text.isEmpty && _results.isNotEmpty) {
      setState(() {
        _results = [];
      });
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_clearIfEmpty);
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
    });

    final res = await _service.search(q, count: 8);

    setState(() {
      _results = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Cari lokasi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                  onSubmitted: _search,
                ),
              ),
            ),

            const SizedBox(width: 8),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => _search(_ctrl.text),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: Color(0xFF6BAAFC),
                  elevation: 4,
                  minimumSize: const Size(48, 48),
                ),
                child: const Icon(Icons.search, color: Colors.white),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        if (_loading) const LinearProgressIndicator(color: Color(0xFF0077B6)),

        if (!_loading && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.builder(
              itemCount: _results.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, idx) {
                final r = _results[idx];
                final display =
                    '${r['name'] ?? ''}, ${r['admin1'] ?? ''} ${r['country'] ?? ''}';

                return ListTile(
                  title:
                      Text(display.trim(), style: const TextStyle(color: Colors.black87)),
                  onTap: () {
                    final loc = LocationModel.fromGeocodingJson(r);
                    widget.onSelect(loc);
                    setState(() => _results = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
