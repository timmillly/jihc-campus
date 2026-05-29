import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/post/create_post_screen.dart';
import 'post_image.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final bool showActions;

  const EventCard({
    super.key,
    required this.event,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked =
        currentUser != null && event.likedBy.contains(currentUser.uid);
    final isAuthor = currentUser?.uid == event.authorId;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (event.imageUrl != null)
              PostImage(
                imageUrl: event.imageUrl!,
                height: 180,
                width: double.infinity,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge + date
                  Row(
                    children: [
                      _CategoryBadge(category: event.category),
                      const Spacer(),
                      Text(
                        _formatDate(event.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          event.location,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Author + Like
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.2),
                        child: Text(
                          event.authorName.isNotEmpty
                              ? event.authorName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.authorName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showActions) ...[
                        // Like button
                        GestureDetector(
                          onTap: () {
                            if (currentUser != null) {
                              FirestoreService()
                                  .toggleLike(event.id, currentUser.uid);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isLiked
                                    ? Colors.red
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.likes}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isLiked
                                      ? Colors.red
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAuthor) ...[
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _openEditPost(context),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Delete button
                          GestureDetector(
                            onTap: () => _confirmDelete(context),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _openEditPost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostScreen(existingPost: event),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService().deletePost(event.id);
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final isEvent = category == 'event';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isEvent
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEvent ? Icons.event_rounded : Icons.newspaper_rounded,
            size: 12,
            color: isEvent ? AppColors.accent : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isEvent ? 'Event' : 'News',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isEvent ? AppColors.accent : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
