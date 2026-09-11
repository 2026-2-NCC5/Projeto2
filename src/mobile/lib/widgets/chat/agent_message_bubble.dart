import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:asa_connect/core/constants.dart';
import 'package:asa_connect/models/chat_message.dart';

class AgentMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final Function(bool isHelpful)? onFeedback;
  final VoidCallback? onEscalate;

  const AgentMessageBubble({
    super.key,
    required this.message,
    this.onFeedback,
    this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final isAbstained = message.isAbstained;
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Nome do Agente e Hora
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isAbstained ? AppColors.abstentionAmber : AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isAbstained ? Icons.warning_amber_rounded : Icons.support_agent_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ASA Connect +',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAbstained ? AppColors.abstentionAmber : AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Card da Bolha de Resposta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAbstained ? AppColors.abstentionBg : AppColors.surfaceCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isAbstained ? AppColors.abstentionBorder : AppColors.borderLight,
                width: isAbstained ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alerta visual quando em abstenção
                if (isAbstained) ...[
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.abstentionAmber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'AVISO DE CONFIANÇA CONTROLADA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Texto da Resposta com Formatação Rica
                FormattedMarkdownText(
                  text: message.content,
                  baseStyle: TextStyle(
                    fontSize: 14,
                    color: isAbstained ? Colors.brown.shade900 : AppColors.textBody,
                    height: 1.45,
                  ),
                ),

                // Chip de Fonte Oficial (RF06, Seção 5)
                if (message.sourceCitation != null && !isAbstained) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 13, color: AppColors.primaryGreen),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            message.sourceCitation!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Ação Sugerida (RF07)
                if (message.suggestedAction != null && !isAbstained) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.accentEmerald),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          message.suggestedAction!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Rodapé com Botões de Feedback e Escalonamento Humano
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botões de Feedback (RF17)
                    if (!isAbstained)
                      Row(
                        children: [
                          InkWell(
                            onTap: () => onFeedback?.call(true),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: message.isHelpful == true ? AppColors.accentMint : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    message.isHelpful == true ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                    size: 13,
                                    color: message.isHelpful == true ? AppColors.primaryGreen : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Útil',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: message.isHelpful == true ? AppColors.primaryGreen : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => onFeedback?.call(false),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: message.isHelpful == false ? const Color(0xFFFEE2E2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    message.isHelpful == false ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                                    size: 13,
                                    color: message.isHelpful == false ? AppColors.error : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Não útil',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: message.isHelpful == false ? AppColors.error : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),

                    // Botão "Falar com o ASA" (Escalonamento Humano)
                    InkWell(
                      onTap: onEscalate,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isAbstained ? 12 : 8,
                          vertical: isAbstained ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAbstained ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAbstained ? AppColors.primaryGreen : AppColors.borderMedium,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.headset_mic_rounded,
                              size: 13,
                              color: isAbstained ? Colors.white : AppColors.textBody,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Falar com o ASA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isAbstained ? FontWeight.bold : FontWeight.w600,
                                color: isAbstained ? Colors.white : AppColors.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FormattedMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const FormattedMarkdownText({
    super.key,
    required this.text,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // Headers ### or ##
      if (trimmed.startsWith('###') || trimmed.startsWith('##')) {
        final title = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              title,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
                fontSize: baseStyle.fontSize! + 0.5,
              ),
            ),
          ),
        );
        continue;
      }

      // Bullets (• or * or -)
      if (trimmed.startsWith('•') || trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
        final content = trimmed.replaceFirst(RegExp(r'^[\•\*\-]\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5, right: 6),
                  child: Icon(Icons.circle, size: 5, color: AppColors.primaryGreen),
                ),
                Expanded(
                  child: RichText(
                    text: _parseSpans(content, baseStyle),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered list (1. 2. etc)
      final numMatch = RegExp(r'^(\d+)[\.\)]\s*(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final content = numMatch.group(2)!;
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accentMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    numStr,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: _parseSpans(content, baseStyle),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Normal paragraph with bold parsing
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(
            text: _parseSpans(trimmed, baseStyle),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  TextSpan _parseSpans(String text, TextStyle style) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: style,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: style.copyWith(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: style,
      ));
    }

    return TextSpan(children: spans);
  }
}
