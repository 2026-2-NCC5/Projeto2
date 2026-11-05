import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/models/conversation.dart';
import 'package:asa_connect/state/chat_provider.dart';
import 'package:asa_connect/screens/chat/chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  final bool isTab;
  final ValueChanged<String>? onSelectConversation;
  final String? selectedConversationId;

  const ConversationsListScreen({
    super.key,
    this.isTab = false,
    this.onSelectConversation,
    this.selectedConversationId,
  });

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final allConversations = chatProvider.conversations;

    final List<ConversationModel> conversations;
    if (_filter.trim().isEmpty) {
      conversations = List.from(allConversations)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } else {
      final q = _filter.trim().toLowerCase();
      final scoredList = <MapEntry<ConversationModel, int>>[];

      for (final c in allConversations) {
        final title = c.title.toLowerCase();
        final lastMsg = (c.lastMessage ?? '').toLowerCase();

        int score = 0;
        if (title == q) {
          score += 100;
        } else if (title.startsWith(q)) {
          score += 70;
        } else if (title.split(' ').any((w) => w.startsWith(q))) {
          score += 50;
        } else if (title.contains(q)) {
          score += 30;
        }

        if (lastMsg.startsWith(q)) {
          score += 20;
        } else if (lastMsg.contains(q)) {
          score += 10;
        }

        if (score > 0) {
          scoredList.add(MapEntry(c, score));
        }
      }

      scoredList.sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return b.key.updatedAt.compareTo(a.key.updatedAt);
      });

      conversations = scoredList.map((e) => e.key).toList();
    }

    final content = Column(
      children: [
        if (widget.onSelectConversation != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(42),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: const Text('Nova Conversa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                chatProvider.startNewChat();
                widget.onSelectConversation!('');
              },
            ),
          ),

        // Campo de Busca de Conversas (Figma tela 10)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: context.inputFillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.primaryTextColor, fontSize: 13),
              onChanged: (val) => setState(() => _filter = val),
              decoration: InputDecoration(
                hintText: 'Buscar conversas...',
                hintStyle: TextStyle(color: context.secondaryTextColor, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: context.secondaryTextColor),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        Expanded(
          child: chatProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: context.secondaryTextColor),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma conversa encontrada.',
                            style: TextStyle(fontSize: 14, color: context.secondaryTextColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: conversations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        final dateStr = DateFormat('dd/MM, HH:mm').format(conv.updatedAt);
                        final isSelected = conv.id == widget.selectedConversationId;

                        return Material(
                          color: isSelected
                              ? (context.isDarkMode
                                  ? AppColors.primaryGreen.withOpacity(0.2)
                                  : AppColors.accentMint.withOpacity(0.5))
                              : context.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              if (widget.onSelectConversation != null) {
                                widget.onSelectConversation!(conv.id);
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(conversationId: conv.id),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryGreen : context.borderColor,
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode
                                          ? AppColors.primaryGreen.withValues(alpha: 0.25)
                                          : AppColors.accentMint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: context.isDarkMode ? const Color(0xFF00E387) : AppColors.primaryGreen,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                conv.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: context.primaryTextColor,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              dateStr,
                                              style: TextStyle(fontSize: 10, color: context.secondaryTextColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          conv.lastMessage ?? 'Conversa com o ASA Connect+',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );

    if (widget.isTab) return content;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.headerColor,
        title: const Text('Conversas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: content,
    );
  }
}
