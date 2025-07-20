import 'package:flutter/material.dart';
import 'package:my_new_movie_app/dummy_real_ad_banner.dart';
import 'package:my_new_movie_app/screens/search/search_page.dart';
//import '../../widgets/dummy_real_ad_banner.dart';
//import '../search/search_page.dart'; // ✅ corrected import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    BollywoodPage(),
    HollywoodPage(),
    SeriesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _pages[_selectedIndex]),
          const DummyRealAdBanner(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Bollywood'),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_filter),
            label: 'Hollywood',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'Series'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SearchScreen(), // ✅ corrected class name
            ),
          );
        },
        child: const Icon(Icons.search),
      ),
    );
  }
}

// Dummy page placeholders
class BollywoodPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Bollywood Movies"));
  }
}

class HollywoodPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Hollywood Movies"));
  }
}

class SeriesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Series"));
  }
}
