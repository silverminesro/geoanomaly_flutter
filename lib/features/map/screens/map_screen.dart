// lib/features/map/screens/map_screen.dart
class MapScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GeoAnomaly'),
        actions: [
          IconButton(
              icon: Icon(Icons.person),
              onPressed: () => context.go('/profile')),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps widget
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(48.1486, 17.1077), // Default location
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              // Map controller setup
            },
            markers: Set<Marker>.from(_zoneMarkers), // Game zones
          ),

          // Floating buttons
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              onPressed: _scanArea,
              child: Icon(Icons.search),
              tooltip: 'Scan Area',
            ),
          ),
        ],
      ),
    );
  }
}
