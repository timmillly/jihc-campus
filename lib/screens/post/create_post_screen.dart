import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class CreatePostScreen extends StatefulWidget {
  final EventModel? existingPost;

  const CreatePostScreen({super.key, this.existingPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _uuid = const Uuid();

  String _category = 'event';
  XFile? _imageFile;
  DateTime? _eventDate;
  bool _loading = false;

  bool get _isEditing => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    final post = widget.existingPost;
    if (post != null) {
      _titleCtrl.text = post.title;
      _descCtrl.text = post.description;
      _locationCtrl.text = post.location;
      _category = post.category;
      _eventDate = post.eventDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _storageService.showImageSourcePicker(context);
    if (file != null) setState(() => _imageFile = file);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _eventDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final postId = widget.existingPost?.id ?? _uuid.v4();
      String? imageUrl;
      var imageUploadFailed = false;

      if (_imageFile != null) {
        try {
          imageUrl =
              await _storageService.uploadEventImage(_imageFile!, postId);
        } catch (storageError) {
          try {
            imageUrl =
                await _storageService.imageAsFirestoreDataUrl(_imageFile!);
          } catch (_) {
            imageUploadFailed = true;
          }
        }
      }

      if (_isEditing) {
        final existing = widget.existingPost!;
        await _firestoreService.updatePost(existing.id, {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'category': _category,
          'eventDate': _category == 'event' && _eventDate != null
              ? Timestamp.fromDate(_eventDate!)
              : null,
          'imageUrl': imageUrl ?? existing.imageUrl,
          'location': _locationCtrl.text.trim(),
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                imageUploadFailed
                    ? 'Post updated, but the image could not be uploaded.'
                    : 'Post updated successfully.',
              ),
              backgroundColor:
                  imageUploadFailed ? AppColors.error : AppColors.success,
            ),
          );
        }
        return;
      }

      final post = EventModel(
        id: postId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        authorId: user.uid,
        authorName: user.displayName ?? 'JIHC Student',
        createdAt: DateTime.now(),
        eventDate: _category == 'event' ? _eventDate : null,
        imageUrl: imageUrl,
        location: _locationCtrl.text.trim(),
      );

      await _firestoreService.createPost(post);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageUploadFailed
                  ? 'Post created, but the image could not be uploaded.'
                  : 'Post created successfully.',
            ),
            backgroundColor:
                imageUploadFailed ? AppColors.error : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.98,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _isEditing ? 'Edit Post' : 'Create Post',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category selector
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _CategoryChip(
                              label: '📅 Event',
                              value: 'event',
                              selected: _category == 'event',
                              onTap: () => setState(() => _category = 'event'),
                            ),
                            const SizedBox(width: 12),
                            _CategoryChip(
                              label: '📰 News',
                              value: 'news',
                              selected: _category == 'news',
                              onTap: () => setState(() => _category = 'news'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Image picker
                        const Text(
                          'Image (optional)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.divider,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        FutureBuilder<Uint8List>(
                                          future: _imageFile!.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return Container(
                                                color: AppColors.background,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }

                                            return Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                                () => _imageFile = null),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 40,
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.6)),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isEditing &&
                                                widget.existingPost?.imageUrl !=
                                                    null
                                            ? 'Current image stays unless you add a new one'
                                            : 'Tap to add image\nCamera or Gallery',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Title *',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter title'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Description
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.description_outlined),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter description'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Location
                        TextFormField(
                          controller: _locationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Location (optional)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        // Event date picker
                        if (_category == 'event') ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.divider),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _eventDate != null
                                        ? DateFormat('dd MMM yyyy')
                                            .format(_eventDate!)
                                        : 'Select event date (optional)',
                                    style: TextStyle(
                                      color: _eventDate != null
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_eventDate != null)
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _eventDate = null),
                                      child: const Icon(Icons.close,
                                          size: 18,
                                          color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_isEditing
                                    ? 'Save Changes'
                                    : 'Publish Post'),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
