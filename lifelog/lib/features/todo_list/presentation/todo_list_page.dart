import 'package:flutter/material.dart';

import '../../../core/widgets/themed_page_content.dart';

class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ThemedPageContent(
      title: 'To-Do List Page',
    );
  }
}
