import 'package:childcompass/provider/parent_provider.dart';
import 'package:childcompass/services/child/child_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeofenceListScreen extends ConsumerStatefulWidget {
  @override
  _GeofenceListScreenState createState() => _GeofenceListScreenState();
}

class _GeofenceListScreenState extends ConsumerState<GeofenceListScreen> {
  List<dynamic> _geofences = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGeofences();
  }

  Future<void> _loadGeofences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final geofences = await childApiService
          .getGeofenceLocations(ref.read(currentChildProvider)!);

      if (geofences == null) {
        setState(() {
          _errorMessage = 'Failed to load geofences';
        });
        return;
      }

      print(geofences);

      setState(() {
        _geofences = geofences;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading geofences: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGeofence(int index) async {
    final geofenceToDelete = _geofences[index];

    final result = await childApiService.removeGeofence(
      childConnectionString: ref.read(currentChildProvider)!,
      geofence: {
        'latitude': geofenceToDelete['latitude'],
        'longitude': geofenceToDelete['longitude'],
      },
    );

    if (result== true) {
      // Refresh the list
      await _loadGeofences();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geofence deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete geofence')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF373E4E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'GeoFence Locations',
          style: TextStyle(color: Colors.white, fontFamily: "Quantico"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh ,color: Colors.white,),
            onPressed: _loadGeofences,
          ),
        ],
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF373E4E),
        child: const Icon(Icons.add,color: Colors.white,),
        onPressed: () async {

          final result = await Navigator.pushNamed(context, '/GeofenceSetupScreen');
          if (result == true) {
            _loadGeofences();
          }

        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_geofences.isEmpty) {
      return const Center(child: Text('No geofences found'));
    }

    return Column(
      children: [
        SizedBox(height: 10,),
        Expanded(
          child: ListView.builder(
            itemCount: _geofences.length,
            itemBuilder: (context, index) {
              final geofence = _geofences[index];
              return _buildGeofenceItem(geofence, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeofenceItem(Map<String, dynamic> geofence, int index) {
    return Card(
      color: Colors.indigo.shade50,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(

        leading: const Icon(Icons.location_on, color: Color(0xFF373E4E)),
        minVerticalPadding: 18,
        title: Text(
          geofence['name'] ?? 'Unnamed Location',
          style: const TextStyle(fontWeight: FontWeight.bold,fontFamily: "Quantico"),
        ),
        subtitle: Text(
          'Radius: ${geofence['radius']}m',

        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteDialog(index),
        ),
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Geofence',style: const TextStyle(fontWeight: FontWeight.normal,fontFamily: "Quantico"), ),
        content: const Text('Are you sure you want to delete this geofence?',style: const TextStyle(fontFamily: "Quantico"),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',style: const TextStyle(fontFamily: "Quantico"),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGeofence(index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red,fontFamily: "Quantico")),
          ),
        ],
      ),
    );
  }
}
