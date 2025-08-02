import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';

class NetworkImageWidget extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const NetworkImageWidget({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<NetworkImageWidget> createState() => _NetworkImageWidgetState();
}

class _NetworkImageWidgetState extends State<NetworkImageWidget> {
  late Future<ImageProvider> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(NetworkImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _loadImage();
    }
  }

  Future<ImageProvider> _loadImage() async {
    try {
      print(
          '🖼️ NetworkImageWidget: Starting to load image: ${widget.imageUrl}');

      // ✅ FIX: Získaj token z ApiClient instance
      final token = await ApiClient.instance.getAuthToken();

      if (token == null) {
        print('❌ NetworkImageWidget: No authentication token available');
        throw Exception('No authentication token available');
      }

      // ✅ FIX: Konštruuj správnu URL
      String fullUrl = _buildFullUrl(widget.imageUrl);

      print('🖼️ NetworkImageWidget: Loading image from: $fullUrl');
      print('🔑 NetworkImageWidget: Using token: ${token.substring(0, 20)}...');

      // ✅ FIX: Stiahni obrázok s autentifikáciou
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'image/*',
          'Content-Type': 'application/json',
        },
      );

      print('📡 NetworkImageWidget: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(
            '✅ NetworkImageWidget: Image loaded successfully, size: ${response.bodyBytes.length} bytes');
        return MemoryImage(response.bodyBytes);
      } else {
        print(
            '❌ NetworkImageWidget: Failed to load image: ${response.statusCode}');
        print('📡 NetworkImageWidget: Response body: ${response.body}');
        throw Exception(
            'Failed to load image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ NetworkImageWidget: Error loading image ${widget.imageUrl}: $e');
      rethrow;
    }
  }

  // ✅ UPDATE: Metóda na konštrukciu úplnej URL
  String _buildFullUrl(String imageUrl) {
    // Ak už je úplná URL, použi ju
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }

    const baseUrl = 'http://91.127.104.68/api/v1';

    // Ak je to media ID path (napr. "/media/123")
    if (imageUrl.startsWith('/media/')) {
      return '$baseUrl$imageUrl';
    }

    // Ak je to len typ artefaktu (napr. "urban_artifact") - fallback
    if (!imageUrl.startsWith('/')) {
      // Toto je fallback pre statické obrázky podľa typu
      // V budúcnosti by si mal použiť skutočné media z backendu
      return '$baseUrl/static/images/artifacts/$imageUrl.png';
    }

    // Ak je to iná relatívna cesta
    return '$baseUrl$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Zobraz placeholder počas načítavania
          return widget.placeholder ?? _buildDefaultPlaceholder();
        } else if (snapshot.hasError) {
          // Zobraz error widget pri chybe
          print(
              '🖼️ NetworkImageWidget: Image widget error: ${snapshot.error}');
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        } else if (snapshot.hasData) {
          // Zobraz načítaný obrázok
          return Image(
            image: snapshot.data!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            errorBuilder: (context, error, stackTrace) {
              print('🖼️ NetworkImageWidget: Image render error: $error');
              return widget.errorWidget ?? _buildDefaultErrorWidget();
            },
          );
        } else {
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        }
      },
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[800],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.imageUrl,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
