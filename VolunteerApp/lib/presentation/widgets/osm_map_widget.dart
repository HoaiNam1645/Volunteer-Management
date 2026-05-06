import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// OpenStreetMap widget tái sử dụng (tile từ tile.openstreetmap.org)
/// - Cho phép kéo marker (drag) → trả về toạ độ mới qua [onPositionChanged]
/// - Có thể chỉ hiển thị (read-only) bằng [draggable: false]
class OsmMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final double height;
  final double zoom;
  final bool draggable;
  final void Function(double lat, double lng)? onPositionChanged;

  const OsmMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.height = 240,
    this.zoom = 15,
    this.draggable = false,
    this.onPositionChanged,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  late final MapController _controller = MapController();
  late LatLng _markerPos;

  @override
  void initState() {
    super.initState();
    _markerPos = _initialPos();
  }

  LatLng _initialPos() {
    final lat = widget.latitude ?? 16.0544; // mặc định Đà Nẵng
    final lng = widget.longitude ?? 108.2022;
    return LatLng(lat, lng);
  }

  @override
  void didUpdateWidget(covariant OsmMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude || widget.longitude != oldWidget.longitude) {
      final newPos = _initialPos();
      setState(() => _markerPos = newPos);
      try {
        _controller.move(newPos, widget.zoom);
      } catch (_) {/* map chưa init */}
    }
  }

  void _handleTap(TapPosition _, LatLng latlng) {
    if (!widget.draggable) return;
    setState(() => _markerPos = latlng);
    widget.onPositionChanged?.call(latlng.latitude, latlng.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _markerPos,
            initialZoom: widget.zoom,
            onTap: _handleTap,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.volunteer.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _markerPos,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
