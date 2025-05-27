import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'connect_screen.dart';

class CommentScreen extends StatefulWidget {
  final Post post;

  const CommentScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  int? replyingToCommentIndex;

  void _addCommentOrReply(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      if (replyingToCommentIndex == null) {
        widget.post.commentData.add({
          'text': text,
          'timestamp': DateTime.now(),
          'likes': 0,
          'isLiked': false,
          'replies': [],
        });
        widget.post.comments = widget.post.commentData.length;
      } else {
        widget.post.commentData[replyingToCommentIndex!]['replies'].add({
          'text': text,
          'timestamp': DateTime.now(),
        });
      }
      replyingToCommentIndex = null;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
       
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context, post),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'save') {
                // Handle save
              } else if (value == 'report') {
                // Handle report
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'save',
                child: Text('Save'),
              ),
              const PopupMenuItem<String>(
                value: 'report',
                child: Text('Report'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Post
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
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
                    child: Image.asset(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPostButton(Icons.thumb_up, post.likes.toString(), isActive: post.isLiked, onTap: () {
                      setState(() {
                        post.isLiked = !post.isLiked;
                        post.likes += post.isLiked ? 1 : -1;
                      });
                    }),
                    _buildPostButton(Icons.comment, '${post.comments} Comments'),
                    _buildPostButton(Icons.share, post.shares.toString()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text("Comments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ...post.commentData.asMap().entries.map((entry) {
            final i = entry.key;
            final comment = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 20),
                      const SizedBox(width: 6),
                      const Text("User", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text(timeago.format(comment['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment['text'], style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.thumb_up, color: comment['isLiked'] ? Colors.blue : Colors.grey, size: 20),
                        onPressed: () {
                          setState(() {
                            comment['isLiked'] = !comment['isLiked'];
                            comment['likes'] += comment['isLiked'] ? 1 : -1;
                          });
                        },
                      ),
                      Text(comment['likes'].toString(), style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (replyingToCommentIndex == i) {
                              replyingToCommentIndex = null;
                            } else {
                              replyingToCommentIndex = i;
                            }
                          });
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.reply, size: 20, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              replyingToCommentIndex == i ? "Write a comment" : "Reply",
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (comment['replies'].isNotEmpty) ...comment['replies'].map<Widget>((reply) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 24.0, top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.account_circle, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(reply['text'], style: const TextStyle(fontSize: 13)),
                                Text(timeago.format(reply['timestamp']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 80),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        color: Colors.white,
        child: Row(
          children: [
            const Icon(Icons.camera_alt, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: replyingToCommentIndex != null ? 'Write a reply...' : 'Write a comment...',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.teal),
              onPressed: () => _addCommentOrReply(_commentController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostButton(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? Colors.blue : Colors.black),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.blue : Colors.black),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isActive ? Colors.blue : Colors.black)),
          ],
        ),
      ),
    );
  }
}
