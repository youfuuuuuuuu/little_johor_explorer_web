import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:little_johor_explorer/data/services/story_service.dart';
import 'package:little_johor_explorer/data/models/story.dart';
import 'package:little_johor_explorer/core/widgets/custom_button.dart';
import 'package:little_johor_explorer/features/screens/admin/manage_story_screen.dart';
import 'package:little_johor_explorer/features/screens/admin/manage_quiz_screen.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final storyService = Provider.of<StoryService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Admin Panel",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.purple,
          tabs: const [
            Tab(icon: Icon(Icons.book_rounded), text: "Stories"),
            Tab(icon: Icon(Icons.quiz_rounded), text: "Quizzes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContentList(context, storyService.stories, isQuizMode: false),
          _buildContentList(context, storyService.stories, isQuizMode: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? "Add Story" : "Add Quiz"),
      ),
    );
  }

  Widget _buildContentList(BuildContext context, List<Story> items,
      {required bool isQuizMode}) {
    if (items.isEmpty) {
      return const Center(child: Text("No items found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade100,
                child: item.coverImageUrl.isNotEmpty
                    ? Image.asset(
                        item.coverImageUrl.replaceFirst('file:///', ''),
                        fit: BoxFit.cover)
                    : const Icon(Icons.image),
              ),
            ),
            title: Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isQuizMode
                ? "${item.quizQuestions.length} Questions"
                : "Order Index: ${item.orderIndex}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text("Are you sure you want to remove '${story.title}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
