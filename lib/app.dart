import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/topology_screen.dart';
import 'services/mesh_store.dart';

class OfflineMeshApp extends StatelessWidget {
  const OfflineMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MeshAppRoot(store: MeshStore());
  }
}

class MeshAppRoot extends StatefulWidget {
  const MeshAppRoot({super.key, required this.store});

  final MeshStore store;

  @override
  State<MeshAppRoot> createState() => _MeshAppRootState();
}

class _MeshAppRootState extends State<MeshAppRoot> {
  late final List<Widget> _pages = <Widget>[
    DashboardScreen(store: widget.store),
    ChatScreen(store: widget.store),
    EmergencyScreen(store: widget.store),
    TopologyScreen(store: widget.store),
    MapsScreen(store: widget.store),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Mesh',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D9EFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F1726),
          background: const Color(0xFF060B14),
        ),
        scaffoldBackgroundColor: const Color(0xFF060B14),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int index) {
            setState(() {
              _index = index;
            });
          },
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Status'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning_amber), label: 'Alert'),
            NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Mesh'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          ],
        ),
      ),
    );
  }
}