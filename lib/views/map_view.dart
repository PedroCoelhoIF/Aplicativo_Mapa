import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../viewmodels/location_viewmodel.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<LocationViewModel>(context, listen: false);
      viewModel.addListener(_onLocationUpdate);
    });
  }

  void _onLocationUpdate() {
    final viewModel = Provider.of<LocationViewModel>(context, listen: false);
    if (viewModel.isTracking && viewModel.currentUserLocation != null) {
      _mapController.move(viewModel.center, viewModel.zoom);
    }
  }

  @override
  void dispose() {
    final viewModel = Provider.of<LocationViewModel>(context, listen: false);
    viewModel.removeListener(_onLocationUpdate);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LocationViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // Mapa
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: viewModel.center,
                  initialZoom: viewModel.zoom,
                  onTap: (tapPosition, point) {
                    viewModel.addMarker(point);
                  },
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && position.zoom != null) {
                      viewModel.setZoom(position.zoom!);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_mapas_osm',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: viewModel.markers.map((latlng) {
                      return Marker(
                        point: latlng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.tealAccent,
                          size: 40,
                        ),
                      );
                    }).toList(),
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),

              // Barra de busca
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1B1F26),
                  child: TypeAheadField<Map<String, dynamic>>(
                    controller: _searchController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Buscar endereço...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1B1F26),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (value) => setState(() {}),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      if (pattern.isEmpty) return [];
                      return await viewModel.searchAddress(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        leading: const Icon(Icons.place, color: Colors.tealAccent),
                        title: Text(
                          suggestion['display_name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        tileColor: const Color(0xFF1B1F26),
                      );
                    },
                    onSelected: (suggestion) {
                      viewModel.selectSearchResult(suggestion);
                      _mapController.move(viewModel.center, viewModel.zoom);
                      FocusScope.of(context).unfocus();
                    },
                    emptyBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Nenhum resultado encontrado',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    errorBuilder: (context, error) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Erro ao buscar endereços',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    loadingBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.tealAccent,
                        ),
                      ),
                    ),
                    decorationBuilder: (context, child) {
                      return Material(
                        type: MaterialType.card,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF1B1F26),
                        child: child,
                      );
                    },
                  ),
                ),
              ),

              // Botões de controle
              Positioned(
                bottom: 100,
                right: 16,
                child: Column(
                  children: [
                    // Botão de rastreamento em tempo real
                    FloatingActionButton(
                      heroTag: 'tracking',
                      onPressed: viewModel.loadingLocation
                          ? null
                          : () {
                              viewModel.toggleTracking();
                              if (viewModel.isTracking) {
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  _mapController.move(viewModel.center, viewModel.zoom);
                                });
                              }
                            },
                      backgroundColor: viewModel.isTracking 
                          ? Colors.redAccent 
                          : Colors.tealAccent,
                      child: viewModel.loadingLocation
                          ? const CircularProgressIndicator(
                              color: Color(0xFF0B0E13),
                              strokeWidth: 2,
                            )
                          : Icon(
                              viewModel.isTracking 
                                  ? Icons.gps_fixed 
                                  : Icons.gps_not_fixed,
                              color: const Color(0xFF0B0E13),
                            ),
                    ),
                    const SizedBox(height: 12),
                    // Botão de localização atual (uma vez)
                    FloatingActionButton(
                      heroTag: 'location',
                      mini: true,
                      onPressed: viewModel.loadingLocation || viewModel.isTracking
                          ? null
                          : () {
                              viewModel.init();
                              Future.delayed(const Duration(milliseconds: 500), () {
                                _mapController.move(viewModel.center, viewModel.zoom);
                              });
                            },
                      backgroundColor: const Color(0xFF1B1F26),
                      child: const Icon(Icons.my_location, color: Colors.tealAccent),
                    ),
                    const SizedBox(height: 12),
                    // Botão de zoom in
                    FloatingActionButton(
                      heroTag: 'zoomin',
                      mini: true,
                      onPressed: () {
                        final newZoom = viewModel.zoom + 1;
                        viewModel.setZoom(newZoom);
                        _mapController.move(viewModel.center, newZoom);
                      },
                      backgroundColor: const Color(0xFF1B1F26),
                      child: const Icon(Icons.add, color: Colors.tealAccent),
                    ),
                    const SizedBox(height: 8),
                    // Botão de zoom out
                    FloatingActionButton(
                      heroTag: 'zoomout',
                      mini: true,
                      onPressed: () {
                        final newZoom = viewModel.zoom - 1;
                        viewModel.setZoom(newZoom);
                        _mapController.move(viewModel.center, newZoom);
                      },
                      backgroundColor: const Color(0xFF1B1F26),
                      child: const Icon(Icons.remove, color: Colors.tealAccent),
                    ),
                  ],
                ),
              ),

              // Informações do marcador (se houver)
              if (viewModel.markers.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1B1F26),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            viewModel.isTracking ? Icons.gps_fixed : Icons.location_on,
                            color: viewModel.isTracking ? Colors.redAccent : Colors.tealAccent,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  viewModel.isTracking 
                                      ? 'Rastreamento Ativo' 
                                      : 'Localização Selecionada',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lat: ${viewModel.markers.first.latitude.toStringAsFixed(6)}\nLon: ${viewModel.markers.first.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!viewModel.isTracking)
                            IconButton(
                              onPressed: () {
                                viewModel.addMarker(viewModel.markers.first);
                              },
                              icon: const Icon(Icons.close, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Indicador de rastreamento ativo (topo)
              if (viewModel.isTracking)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.redAccent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Rastreando sua localização',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}