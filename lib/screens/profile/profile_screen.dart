import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/event_card.dart';
import '../../widgets/post_image.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _storageService = StorageService();
  late TabController _tabController;
  bool _uploading = false;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfilePhoto();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _changeProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final file = await _storageService.showImageSourcePicker(context);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      String url;
      try {
        url = await _storageService.uploadProfileImage(file, user.uid);
        await user.updatePhotoURL(url);
      } catch (_) {
        url = await _storageService.imageAsFirestoreDataUrl(file);
      }

      await _authService.updatePhotoUrl(user.uid, url);
      setState(() => _profilePhotoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _loadProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userData = await _authService.getUserData(user.uid);
    if (!mounted) return;

    setState(() {
      _profilePhotoUrl = userData?.photoUrl ?? user.photoURL;
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = _profilePhotoUrl ?? user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── PERSONAL IDENTITY BLOCK (criterion #6) ───────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accentLight],
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _uploading
                        ? Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                          )
                        : CircleAvatar(
                            radius: 45,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Text(
                                    AppConstants.studentName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : ClipOval(
                                    child: PostImage(
                                      imageUrl: photoUrl,
                                      width: 90,
                                      height: 90,
                                    ),
                                  ),
                          ),
                    GestureDetector(
                      onTap: _changeProfilePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── HARDCODED STUDENT NAME ──
                const Text(
                  AppConstants.studentName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // ── HARDCODED STUDENT ID ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ID: ${AppConstants.studentId}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // ── ACCENT COLOR ──
                Text(
                  'Accent: ${AppConstants.assignedColor}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.accent,
              tabs: const [
                Tab(text: 'My Posts'),
                Tab(text: 'About App'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My posts
                _MyPostsTab(userId: user?.uid ?? ''),
                // About
                _AboutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyPostsTab extends StatelessWidget {
  final String userId;
  const _MyPostsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Center(child: Text('Please log in'));
    }
    return StreamBuilder<List<EventModel>>(
      stream: FirestoreService().myPostsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.post_add_rounded,
                    size: 60, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text(
                  "You haven't posted anything yet.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (_, i) => EventCard(event: posts[i]),
        );
      },
    );
  }
}

class _AboutTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutCard(
            icon: Icons.school_rounded,
            title: 'JIHC Campus Hub',
            description:
                'The official campus events and news app for Jabil International High College students. Stay connected with everything happening on campus.',
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.person_pin_rounded,
            title: 'Developer',
            description:
                '${AppConstants.studentName}\nStudent ID: ${AppConstants.studentId}',
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.palette_rounded,
            title: 'Assigned Accent Color',
            description: AppConstants.assignedColor,
            accentColor: AppColors.accent,
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.info_outline_rounded,
            title: 'Features',
            description:
                '• Google Sign-In & Email/Password Auth\n• Real-time Campus Events & News\n• Firebase Storage for Images\n• Create, Read, Update, Delete Posts\n• Like & interact with posts\n• 25+ screens across 5 sections',
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? accentColor;

  const _AboutCard({
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (accentColor ?? AppColors.accent).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor ?? AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
