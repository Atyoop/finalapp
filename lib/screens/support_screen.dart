import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/support_provider.dart';
import '../providers/user_provider.dart';
import '../models/support_ticket.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _categoryController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'BugReport';

  final List<String> _categories = [
    'BugReport',
    'TechnicalIssue',
    'PaymentProblem',
    'PremiumSubscription',
    'Suggestion',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    final supportProvider = context.read<SupportProvider>();
    final userProvider = context.read<UserProvider>();
    if (userProvider.token != null) {
      supportProvider.fetchMyTickets(userProvider.token!);
    }
  }

  Future<void> _submitSupport() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    final supportProvider = context.read<SupportProvider>();
    final userProvider = context.read<UserProvider>();

    if (userProvider.token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Authentication required')));
      return;
    }

    final success = await supportProvider.submitSupportRequest(
      token: userProvider.token!,
      category: _selectedCategory,
      message: _messageController.text.trim(),
    );

    if (mounted) {
      if (success) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support request submitted successfully.'),
            duration: Duration(seconds: 3),
          ),
        );
        // Reload tickets
        _loadTickets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${supportProvider.error}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'IT Support',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer2<SupportProvider, UserProvider>(
        builder: (context, supportProvider, userProvider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Submit support form
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit a Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category dropdown
                        Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            underline: const SizedBox(),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(category),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Message field
                        Text(
                          'Message',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          minLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Describe your issue...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: supportProvider.isSubmitting
                                ? null
                                : _submitSupport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              disabledBackgroundColor: Colors.grey[400],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: supportProvider.isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Submit Request',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Ticket history
                  Text(
                    'Your Tickets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (supportProvider.isFetching)
                    const Center(child: CircularProgressIndicator())
                  else if (supportProvider.tickets.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No support tickets yet',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: supportProvider.tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ticket = supportProvider.tickets[index];
                        return _SupportTicketCard(ticket: ticket);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SupportTicketCard extends StatefulWidget {
  final SupportTicket ticket;

  const _SupportTicketCard({required this.ticket});

  @override
  State<_SupportTicketCard> createState() => _SupportTicketCardState();
}

class _SupportTicketCardState extends State<_SupportTicketCard> {
  bool _isExpanded = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'inprogress':
        return Colors.blue;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${widget.ticket.ticketId} - ${widget.ticket.category}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.ticket.createdAt.year}-${widget.ticket.createdAt.month.toString().padLeft(2, '0')}-${widget.ticket.createdAt.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          widget.ticket.status,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.ticket.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(widget.ticket.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.ticket.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.ticket.adminReply != null) ...[
            Divider(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Admin Reply',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primaryTeal,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              Divider(height: 1, color: Colors.grey[200]),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  widget.ticket.adminReply!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
