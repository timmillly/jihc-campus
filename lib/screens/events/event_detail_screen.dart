import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_image.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked =
        currentUser != null && event.likedBy.contains(currentUser.uid);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: event.imageUrl != null ? 280 : 0,
            pinned: true,
            flexibleSpace: event.imageUrl != null
                ? FlexibleSpaceBar(
                    background: PostImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: event.category == 'event'
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.category == 'event' ? '📅 Event' : '📰 News',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: event.category == 'event'
                            ? AppColors.accent
                            : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Meta info
                  _MetaRow(
                    icon: Icons.person_outline,
                    text: event.authorName,
                  ),
                  const SizedBox(height: 8),
                  _MetaRow(
                    icon: Icons.calendar_today_outlined,
                    text: DateFormat('dd MMMM yyyy, HH:mm')
                        .format(event.createdAt),
                  ),
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.location_on_outlined,
                      text: event.location,
                    ),
                  ],
                  if (event.eventDate != null) ...[
                    const SizedBox(height: 8),
                    _MetaRow(
                      icon: Icons.event_rounded,
                      text:
                          'Event date: ${DateFormat('dd MMM yyyy').format(event.eventDate!)}',
                      color: AppColors.accent,
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Like button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (currentUser != null) {
                          FirestoreService()
                              .toggleLike(event.id, currentUser.uid);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isLiked
                              ? Colors.red.withValues(alpha: 0.1)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isLiked ? Colors.red : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked
                                  ? Colors.red
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${event.likes} Likes',
                              style: TextStyle(
                                color: isLiked
                                    ? Colors.red
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
