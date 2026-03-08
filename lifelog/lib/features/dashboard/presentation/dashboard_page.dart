import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/notification_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = '';
  String _dailyQuote = '';
  bool _isLoadingQuote = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchDailyQuote();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<void> _fetchDailyQuote() async {
    final notificationService = NotificationService();
    final quote = await notificationService.getDailyQuote();
    if (mounted) {
      setState(() {
        _dailyQuote = quote;
        _isLoadingQuote = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDCE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Hello $_userName!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2B3A55),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome to your Dashboard.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2B3A55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _buildQuoteCard(),
              const SizedBox(height: 32),
              // Main content for Dashboard goes here
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.format_quote, color: Color(0xFF3B4863)),
              SizedBox(width: 8),
              Text(
                'Quote of the Day',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B4863),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingQuote
              ? const Center(child: CircularProgressIndicator())
              : Text(
                  '"$_dailyQuote"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF2B3A55),
                  ),
                ),
        ],
      ),
    );
  }
}
