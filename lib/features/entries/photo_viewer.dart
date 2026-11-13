import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../shared/context_ext.dart';
import 'entry_text.dart';

/// Loads a saved photo's bytes from the photo folder. Shows a placeholder when
/// the file is missing.
class SavedPhotoImage extends StatelessWidget {
  const SavedPhotoImage({
    super.key,
    required this.entryId,
    required this.photo,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });
  final String entryId;
  final Photo photo;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final file = context.services.photos.fileFor(entryId, photo.fileName);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snap) {
        if (snap.data == true) {
          return Image.file(file,
              fit: fit,
              cacheWidth: cacheWidth,
              errorBuilder: (_, _, _) => _missing(context));
        }
        return snap.connectionState == ConnectionState.done
            ? _missing(context)
            : const SizedBox.shrink();
      },
    );
  }

  Widget _missing(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.broken_image_outlined, color: Color(0xFF9FB3AA), size: 36),
          const SizedBox(height: 6),
          Text(context.l10n.photoMissing,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFC4D0CB), fontSize: 13)),
        ]),
      );
}

/// Full-size photo viewer with next / previous and thumbnails (INC-7, DET-1).
/// The label is shown with every photo (INC-10).
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen(
      {super.key, required this.entry, required this.photos, this.initial = 0});
  final Entry entry;
  final List<Photo> photos;
  final int initial;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late int _index = widget.initial;

  void _go(int delta) {
    final n = widget.photos.length;
    setState(() => _index = (_index + delta + n) % n);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final p = widget.photos[_index];
    final e = widget.entry;
    return Scaffold(
      backgroundColor: const Color(0xFF141A18),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${receiptNoLabel(l, e.type)} ${fmt.integer(e.receiptNo)} · ${displayName(l, e)}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                      '${l.photoOf(fmt.integer(_index + 1), fmt.integer(widget.photos.length))} · ${p.label}',
                      style: const TextStyle(color: Color(0xFFC4D0CB), fontSize: 13)),
                ]),
              ),
              IconButton.filled(
                tooltip: l.closePhoto,
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2A3330),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(44, 44)),
                icon: const Icon(Icons.close, size: 18),
              ),
            ]),
          ),
          Expanded(
            child: Row(children: [
              const SizedBox(width: 16),
              _NavButton(icon: Icons.chevron_left, label: l.prevPhoto, onTap: () => _go(-1)),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Semantics(
                      label: p.label,
                      image: true,
                      child: SavedPhotoImage(
                          key: ValueKey(p.id),
                          entryId: e.id,
                          photo: p,
                          fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _NavButton(icon: Icons.chevron_right, label: l.nextPhoto, onTap: () => _go(1)),
              const SizedBox(width: 16),
            ]),
          ),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              itemCount: widget.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => Semantics(
                button: true,
                selected: i == _index,
                label: widget.photos[i].label,
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    width: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3330),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: i == _index ? Colors.white : const Color(0xFF2A3330),
                          width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SavedPhotoImage(
                        entryId: e.id, photo: widget.photos[i], cacheWidth: 200),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton.filled(
        tooltip: label,
        onPressed: onTap,
        style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF2A3330),
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48)),
        icon: Icon(icon),
      );
}

/// Used by the form: shows a photo that is not saved yet.
class DraftPhotoImage extends StatelessWidget {
  const DraftPhotoImage({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) =>
      Image.memory(bytes, fit: BoxFit.cover, cacheWidth: 300, gaplessPlayback: true);
}
