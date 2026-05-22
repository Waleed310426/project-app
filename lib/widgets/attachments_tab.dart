// lib/widgets/attachments_tab.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // استيراد حزمة المشاركة
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:animate_do/animate_do.dart';
import '../helpers/database_helper.dart';
import '../models/attachment_model.dart';
// ✅✅✅ [تصحيح] إضافة هذا السطر لاستيراد الحزمة

enum AttachmentFilter { all, images, videos, documents, others }
enum AttachmentSort { dateDesc, dateAsc, nameAsc, sizeDesc }

class AttachmentsTab extends StatefulWidget {
  final String? projectId;
  final String? taskId;

  const AttachmentsTab({super.key, this.projectId, this.taskId})
      : assert(projectId != null || taskId != null);

  @override
  State<AttachmentsTab> createState() => _AttachmentsTabState();
}

class _AttachmentsTabState extends State<AttachmentsTab> {
  List<Attachment> _allAttachments = [];
  List<Attachment> _filteredAttachments = [];
  bool _isLoading = true;

  String _searchQuery = '';
  AttachmentFilter _currentFilter = AttachmentFilter.all;
  AttachmentSort _currentSort = AttachmentSort.dateDesc;
  bool _isSelectionMode = false;
  final Set<String> _selectedAttachmentIds = {};

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    List<Map<String, dynamic>> data;
    if (widget.projectId != null) {
      data = await DatabaseHelper.instance.getAttachmentsForProject(widget.projectId!);
    } else {
      data = await DatabaseHelper.instance.getAttachmentsForTask(widget.taskId!);
    }

    _allAttachments = data.map((map) => Attachment.fromMap(map)).toList();
    _applyFilterAndSort();
    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilterAndSort() {
    List<Attachment> tempAttachments = List.from(_allAttachments);

    switch (_currentFilter) {
      case AttachmentFilter.images:
        tempAttachments = tempAttachments.where((a) => ['jpg', 'jpeg', 'png', 'gif'].contains(a.fileType)).toList();
        break;
      case AttachmentFilter.videos:
        tempAttachments = tempAttachments.where((a) => ['mp4', 'mov', 'avi'].contains(a.fileType)).toList();
        break;
      case AttachmentFilter.documents:
        tempAttachments = tempAttachments.where((a) => ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(a.fileType)).toList();
        break;
      case AttachmentFilter.others:
        final knownTypes = {'jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'};
        tempAttachments = tempAttachments.where((a) => !knownTypes.contains(a.fileType)).toList();
        break;
      case AttachmentFilter.all:
      default:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      tempAttachments = tempAttachments.where((att) => att.fileName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    switch (_currentSort) {
      case AttachmentSort.nameAsc:
        tempAttachments.sort((a, b) => a.fileName.compareTo(b.fileName));
        break;
      case AttachmentSort.sizeDesc:
        tempAttachments.sort((a, b) => (b.fileSize ?? 0).compareTo(a.fileSize ?? 0));
        break;
      case AttachmentSort.dateAsc:
        tempAttachments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case AttachmentSort.dateDesc:
      default:
        tempAttachments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _filteredAttachments = tempAttachments;
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedAttachmentIds.contains(id)) {
        _selectedAttachmentIds.remove(id);
      } else {
        _selectedAttachmentIds.add(id);
      }
      _isSelectionMode = _selectedAttachmentIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAttachmentIds.clear();
      _isSelectionMode = false;
    });
  }

  // ✅ [تعديل] دالة الحذف الآن تستدعي حوار التأكيد
  Future<void> _handleDeleteRequest() async {
    final bool? confirmed = await _showDeleteConfirmationDialog();
    if (confirmed == true) {
      for (var id in _selectedAttachmentIds) {
        try {
          final attachment = _allAttachments.firstWhere((att) => att.id == id);
          final file = File(attachment.filePath);
          if (await file.exists()) {
            await file.delete();
          }
          if (attachment.thumbnailPath != null) {
            final thumbFile = File(attachment.thumbnailPath!);
            if (await thumbFile.exists()) {
              await thumbFile.delete();
            }
          }
          await DatabaseHelper.instance.deleteAttachment(id);
        } catch (e) {
          print("Error deleting attachment with id $id: $e");
        }
      }
      _clearSelection();
      _loadAttachments();
    }
  }

  // ✅ [تعديل] دالة المشاركة
  Future<void> _shareSelectedFiles() async {
    if (_selectedAttachmentIds.isEmpty) return;

    final filesToShare = _allAttachments
        .where((att) => _selectedAttachmentIds.contains(att.id))
        .map((att) => XFile(att.filePath))
        .toList();

    if (filesToShare.isNotEmpty) {
      await Share.shareXFiles(
        filesToShare,
        text: 'مرفقات من تطبيق تاسكلي',
      );
    }
    _clearSelection();
  }

  Future<void> _addAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
    if (!await attachmentsDir.exists()) await attachmentsDir.create(recursive: true);

    for (var file in result.files) {
      if (file.path == null) continue;
      
      final newPath = p.join(attachmentsDir.path, '${const Uuid().v4()}${p.extension(file.name)}');
      await File(file.path!).copy(newPath);
      
      String? thumbnailPath;
      final fileType = file.extension?.toLowerCase();
      if (fileType == 'mp4' || fileType == 'mov') {
        thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: newPath,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.PNG,
          quality: 75,
        );
      }
      
      final newAttachment = Attachment.createNew(
        fileName: file.name,
        filePath: newPath,
        fileType: fileType,
        fileSize: file.size,
        projectId: widget.projectId,
        taskId: widget.taskId,
        uploadedByUserId: 'user_main_001',
        thumbnailPath: thumbnailPath,
      );
      
      await DatabaseHelper.instance.saveAttachment(newAttachment.toMap());
    }
    _loadAttachments();
  }

  void _openAttachment(Attachment attachment) {
    final fileType = attachment.fileType ?? '';
    if (['jpg', 'jpeg', 'png', 'gif'].contains(fileType)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewerScreen(attachment: attachment)));
    } else if (['mp4', 'mov', 'avi'].contains(fileType)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoViewerScreen(attachment: attachment)));
    } else {
      OpenFilex.open(attachment.filePath);
    }
  }

  // ✅ [تعديل] دالة عرض حوار التأكيد
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من رغبتك في حذف ${_selectedAttachmentIds.length} مرفق(ات) بشكل نهائي؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('نعم، حذف'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _isSelectionMode ? _buildSelectionToolbar() : _buildSearchAndFilterToolbar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAttachments.isEmpty
                    ? const Center(child: Text('لا توجد مرفقات.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: _filteredAttachments.length,
                        itemBuilder: (context, index) {
                          final attachment = _filteredAttachments[index];
                          return AttachmentCard(
                            attachment: attachment,
                            isSelected: _selectedAttachmentIds.contains(attachment.id),
                            onTap: () => _isSelectionMode ? _toggleSelection(attachment.id) : _openAttachment(attachment),
                            onLongPress: () => _toggleSelection(attachment.id),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'attachments_fab',
        onPressed: _addAttachments,
        child: const Icon(Icons.attach_file_rounded),
      ),
    );
  }

  Widget _buildSearchAndFilterToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() { _searchQuery = value; _applyFilterAndSort(); }),
              decoration: InputDecoration(
                hintText: 'ابحث في المرفقات...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<AttachmentSort>(
            onSelected: (sort) => setState(() { _currentSort = sort; _applyFilterAndSort(); }),
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: AttachmentSort.dateDesc, child: Text('الأحدث أولاً')),
              const PopupMenuItem(value: AttachmentSort.dateAsc, child: Text('الأقدم أولاً')),
              const PopupMenuItem(value: AttachmentSort.nameAsc, child: Text('حسب الاسم')),
              const PopupMenuItem(value: AttachmentSort.sizeDesc, child: Text('حسب الحجم')),
            ],
          ),
          PopupMenuButton<AttachmentFilter>(
            onSelected: (filter) => setState(() { _currentFilter = filter; _applyFilterAndSort(); }),
            icon: const Icon(Icons.filter_list_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(value: AttachmentFilter.all, child: Text('الكل')),
              const PopupMenuItem(value: AttachmentFilter.images, child: Text('الصور')),
              const PopupMenuItem(value: AttachmentFilter.videos, child: Text('الفيديو')),
              const PopupMenuItem(value: AttachmentFilter.documents, child: Text('المستندات')),
              const PopupMenuItem(value: AttachmentFilter.others, child: Text('أخرى')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
          Text('${_selectedAttachmentIds.length} تم تحديده', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          // ✅ [تعديل] استدعاء دالة طلب الحذف
          IconButton(tooltip: 'حذف', icon: const Icon(Icons.delete_outline), onPressed: _handleDeleteRequest),
          // ✅ [تعديل] استدعاء دالة المشاركة
          IconButton(tooltip: 'مشاركة', icon: const Icon(Icons.share_outlined), onPressed: _shareSelectedFiles),
        ],
      ),
    );
  }
}

class AttachmentCard extends StatelessWidget {
  final Attachment attachment;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AttachmentCard({super.key, required this.attachment, required this.isSelected, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: FadeInUp(
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2.5),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnail(),
              _buildGradientOverlay(),
              _buildFileInfo(),
              if (isSelected) _buildSelectionCheck(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final fileType = attachment.fileType ?? '';
    if (['jpg', 'jpeg', 'png', 'gif'].contains(fileType)) {
      return Image.file(File(attachment.filePath), fit: BoxFit.cover);
    }
    if (attachment.thumbnailPath != null) {
      return Image.file(File(attachment.thumbnailPath!), fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey.shade200,
      child: Icon(_getIconForFileType(fileType), size: 48, color: Colors.grey.shade600),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.7), Colors.transparent, Colors.black.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attachment.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (attachment.fileSize != null)
            Text(
              '${(attachment.fileSize! / 1024 / 1024).toStringAsFixed(2)} MB',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionCheck(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18),
      ),
    );
  }

  IconData _getIconForFileType(String? fileType) {
    switch (fileType) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      case 'xls': case 'xlsx': return Icons.assessment_rounded;
      case 'ppt': case 'pptx': return Icons.slideshow_rounded;
      case 'zip': case 'rar': return Icons.archive_rounded;
      case 'mp4': case 'mov': return Icons.videocam_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }
}

class ImageViewerScreen extends StatelessWidget {
  final Attachment attachment;
  const ImageViewerScreen({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(attachment.fileName)),
      body: Center(
        child: PhotoView(
          imageProvider: FileImage(File(attachment.filePath)),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}

class VideoViewerScreen extends StatefulWidget {
  final Attachment attachment;
  const VideoViewerScreen({super.key, required this.attachment});

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.attachment.filePath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(widget.attachment.fileName)),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        }),
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
