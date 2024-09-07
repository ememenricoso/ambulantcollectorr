import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectVendorsScreen extends StatefulWidget {

  
  const SelectVendorsScreen({
    Key? key,

  }) : super(key: key);

  @override
  _SelectVendorsScreenState createState() => _SelectVendorsScreenState();
}

class _SelectVendorsScreenState extends State<SelectVendorsScreen> {
  List<String> selectedVendors = [];
  String searchQuery = '';
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchApprovedVendors();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _fetchApprovedVendors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'Approved')
          .get();

      setState(() {
        _vendors = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'full_name': '${data['first_name']} ${data['last_name']}',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle errors here
      print("Error fetching vendors: $e");
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredVendors = _vendors.where((vendor) {
      return vendor['full_name']!.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Vendors"),
        backgroundColor: const Color.fromARGB(255, 33, 168, 53),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Stack(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query;
                    });
                  },
                  style: const TextStyle(color: Color.fromARGB(255, 17, 16, 16)),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: const TextStyle(color: Color.fromARGB(255, 12, 11, 11)),
                    border: const UnderlineInputBorder(), // Line style
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 48, 215, 36)),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredVendors.isEmpty
                    ? const Center(child: Text("No approved vendors found."))
                    : ListView.builder(
                        itemCount: filteredVendors.length,
                        itemBuilder: (context, index) {
                          var vendor = filteredVendors[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            title: RichText(
                              text: TextSpan(
                                children: _highlightMatches(
                                  vendor['full_name'] as String,
                                  searchQuery,
                                ),
                                style: const TextStyle(fontSize: 16, color: Colors.black),
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (selectedVendors.contains(vendor['id'])) {
                                    selectedVendors.remove(vendor['id']);
                                  } else {
                                    selectedVendors.add(vendor['id']);
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color.fromARGB(255, 110, 184, 31), width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                selectedVendors.contains(vendor['id']) ? 'Undo' : 'Send',
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                print('Selected Vendors: $selectedVendors');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 59, 189, 38),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightMatches(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    List<TextSpan> spans = [];
    RegExp regExp = RegExp(RegExp.escape(query), caseSensitive: false);
    Iterable<RegExpMatch> matches = regExp.allMatches(text);

    int start = 0;
    for (var match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }
}
