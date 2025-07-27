import 'package:flutter/material.dart';
import 'package:my_new_movie_app/screens/bollywood_page.dart';

//import 'bollywood_page.dart';
import 'hollywood_page.dart';
import 'series_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellowAccent,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Bollywood'),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_filter),
            label: 'Hollywood',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'Series/Anime'),
        ],
      ),
    );
  }
}
