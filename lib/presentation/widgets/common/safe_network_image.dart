import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/cloudinary_service.dart';

/// A wrapper that safely displays remote images with automatic WebP/Auto compression for Cloudinary.
/// On Web, it uses `Image.network` with `webHtmlElementStrategy` to bypass CORS.
/// On Mobile/Desktop, it uses `CachedNetworkImage`.
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Automatically apply WebP format, auto quality and optional resize on Cloudinary CDN
    final targetMaxWidth = width != null && width! > 0 ? (width! * 2).round() : null;
    final optimizedUrl = CloudinaryService.optimizeUrl(imageUrl, maxWidth: targetMaxWidth);

    if (kIsWeb) {
      return Image.network(
        optimizedUrl,
        fit: fit,
        width: width,
        height: height,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      );
    } else {
      return CachedNetworkImage(
        imageUrl: optimizedUrl,
        fit: fit,
        width: width,
        height: height,
        errorWidget: errorBuilder != null 
            ? (context, url, error) => errorBuilder!(context, error, null)
            : null,
        placeholder: loadingBuilder != null
            ? (context, url) => loadingBuilder!(context, const SizedBox(), null)
            : null,
      );
    }
  }
}
