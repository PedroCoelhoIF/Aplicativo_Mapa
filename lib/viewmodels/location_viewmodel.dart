import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

class LocationViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  StreamSubscription<dynamic>? _positionStreamSubscription;

  LatLng _center = LatLng(-23.55052, -46.633308); 
  LatLng get center => _center;

  double _zoom = 13.0;
  double get zoom => _zoom;

  List<LatLng> _markers = [];
  List<LatLng> get markers => _markers;

  bool _loadingLocation = false;
  bool get loadingLocation => _loadingLocation;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  LatLng? _currentUserLocation;
  LatLng? get currentUserLocation => _currentUserLocation;

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }

  /// Inicializa e obtém a localização atual uma vez
  void init() async {
    try {
      _loadingLocation = true;
      notifyListeners();
      final pos = await _locationService.getCurrentLocation();
      _center = LatLng(pos.latitude, pos.longitude);
      _currentUserLocation = LatLng(pos.latitude, pos.longitude);
      _markers = [LatLng(pos.latitude, pos.longitude)];
      _zoom = 15.0;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter localização: $e');
      }
    } finally {
      _loadingLocation = false;
      notifyListeners();
    }
  }

  /// Inicia o rastreamento contínuo da posição
  void startTracking() async {
    if (_isTracking) return;

    try {
      _loadingLocation = true;
      notifyListeners();

      // Primeiro obtém a localização atual
      final pos = await _locationService.getCurrentLocation();
      _center = LatLng(pos.latitude, pos.longitude);
      _currentUserLocation = LatLng(pos.latitude, pos.longitude);
      _markers = [LatLng(pos.latitude, pos.longitude)];
      _zoom = 16.0;

      // Inicia o stream de localização
      _positionStreamSubscription = _locationService.getPositionStream().listen(
        (position) {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
          _center = LatLng(position.latitude, position.longitude);
          
          // Atualiza o marcador com a nova posição
          if (_markers.isNotEmpty) {
            _markers[0] = LatLng(position.latitude, position.longitude);
          } else {
            _markers.add(LatLng(position.latitude, position.longitude));
          }
          
          notifyListeners();
        },
        onError: (error) {
          if (kDebugMode) {
            print('Erro no stream de localização: $error');
          }
          stopTracking();
        },
      );

      _isTracking = true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao iniciar rastreamento: $e');
      }
      _isTracking = false;
    } finally {
      _loadingLocation = false;
      notifyListeners();
    }
  }

  /// Para o rastreamento contínuo
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationService.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  /// Alterna entre rastreamento ligado/desligado
  void toggleTracking() {
    if (_isTracking) {
      stopTracking();
    } else {
      startTracking();
    }
  }

  void setCenter(LatLng latlng, {double? zoomTo}) {
    _center = latlng;
    if (zoomTo != null) _zoom = zoomTo;
    notifyListeners();
  }

  void addMarker(LatLng latlng) {
    // Se estiver rastreando, não permite adicionar marcadores manuais
    if (_isTracking) return;
    
    _markers = [latlng];
    notifyListeners();
  }

  void setZoom(double z) {
    _zoom = z;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search')
        .replace(queryParameters: {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '5'
    });

    final response = await http.get(uri, headers: {
      'User-Agent': 'FlutterMapApp/1.0 (youremail@example.com)'
    });

    if (response.statusCode != 200) return [];
    final List data = json.decode(response.body);
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  void selectSearchResult(Map<String, dynamic> result) {
    // Para o rastreamento ao buscar um endereço
    if (_isTracking) {
      stopTracking();
    }
    
    final lat = double.tryParse(result['lat']?.toString() ?? '0') ?? 0;
    final lon = double.tryParse(result['lon']?.toString() ?? '0') ?? 0;
    final latlng = LatLng(lat, lon);
    setCenter(latlng, zoomTo: 17.0);
    addMarker(latlng);
  }
}