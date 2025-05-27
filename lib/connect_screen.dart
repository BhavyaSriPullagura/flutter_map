import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

import 'comment.dart';
import 'write_post_screen.dart';

class Post {
  String name;
  DateTime timestamp;
  String title;
  String content;
  String? imageUrl;
  int likes;
  int comments;
  int shares;
  bool isLiked;
  List<Map<String, dynamic>> commentData;
  String body;

  Post({
    required this.name,
    required this.timestamp,
    required this.title,
    required this.content,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
    List<Map<String, dynamic>>? commentData,
  })  : commentData = commentData ?? [],
        body = content;
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({Key? key}) : super(key: key);

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> with WidgetsBindingObserver {
  final List<Post> _posts = [
    Post(
      name: 'Soumya Kumar',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      title: 'Electric, bamboo or modular toothbrush?',
      content: 'Which among the three are best for minimal impact on the planet?',
      likes: 18,
    ),
    Post(
      name: 'Anu',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      title: 'Trees save us',
      content: 'Good for the environment',
      imageUrl: 'assets/ex.jpg',
      likes: 18,
    ),
  ];

  Post? _pendingSharePost;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingSharePost != null) {
      setState(() {
        _pendingSharePost!.shares++;
        _pendingSharePost = null;
      });
    }
  }

  void _navigateToWritePost() async {
    final newPost = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WritePostScreen()),
    );

    if (newPost != null && newPost is Post) {
      setState(() {
        _posts.add(newPost);
      });
    }
  }

  void _navigateToComments(Post post) async {
    final updatedPost = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentScreen(post: post)),
    );

    if (updatedPost != null && updatedPost is Post) {
      setState(() {
        final index = _posts.indexOf(post);
        if (index != -1) {
          updatedPost.comments = updatedPost.commentData.length;
          _posts[index] = updatedPost;
        }
      });
    }
  }

  void _sharePost(Post post) async {
    _pendingSharePost = post;
    final content = '${post.title}\n\n${post.content}';
    await Share.share(content); // returns immediately after launching
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 0, backgroundColor: Colors.white),
      body: ListView(
        children: [
          const Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/profile.jpg')),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToWritePost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFB3E5FC)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Post your recycle stories', style: TextStyle(color: Colors.teal)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          for (var post in _posts)
            GestureDetector(
              onTap: () => _navigateToComments(post),
              child: PostCard(
                post: post,
                onLikeToggle: () => setState(() {
                  post.isLiked = !post.isLiked;
                  post.isLiked ? post.likes++ : post.likes--;
                }),
                onCommentTap: () => _navigateToComments(post),
                onShareTap: () => _sharePost(post),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Pickups'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Connect'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Insights'),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikeToggle,
    required this.onCommentTap,
    required this.onShareTap,
  });

  void _onMenuSelected(BuildContext context, String value) {
    final message = value == 'save' ? 'Post saved' : 'Post reported';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/pic.jpg')),
              const SizedBox(width: 8),
              Text(post.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text(timeago.format(post.timestamp), style: const TextStyle(color: Colors.black)),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) => _onMenuSelected(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'save', child: ListTile(leading: Icon(Icons.bookmark_border), title: Text('Save'))),
                  const PopupMenuItem(value: 'report', child: ListTile(leading: Icon(Icons.report_gmailerrorred), title: Text('Report'))),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(post.content, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                post.imageUrl!,
                width: screenWidth - screenWidth * 0.08,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLikeToggle,
                  icon: Icon(Icons.thumb_up_alt_outlined, color: post.isLiked ? Colors.blue : Colors.black, size: 18),
                  label: Text('${post.likes}', style: TextStyle(color: post.isLiked ? Colors.blue : Colors.black)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: post.isLiked ? Colors.blue : Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCommentTap,
                  icon: const Icon(Icons.comment_outlined, color: Colors.black, size: 18),
                  label: Text('${post.comments} comments', style: const TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShareTap,
                  icon: const Icon(Icons.share_outlined, color: Colors.black, size: 18),
                  label: Text('${post.shares}', style: const TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}










