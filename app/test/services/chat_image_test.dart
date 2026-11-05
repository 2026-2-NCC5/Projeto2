import 'package:flutter_test/flutter_test.dart';
import 'package:asa_connect/models/chat_message.dart';

void main() {
  group('ChatMessage with Image Tests', () {
    test('Serializa e desserializa ChatMessageModel com imageUrl', () {
      final json = {
        'id': 'msg_img_123',
        'conversation_id': 'conv_456',
        'sender': 'USER',
        'content': 'Estou com este erro na tela',
        'image_url': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA',
        'created_at': '2026-10-01T14:30:00Z',
      };

      final msg = ChatMessageModel.fromJson(json);
      expect(msg.id, equals('msg_img_123'));
      expect(msg.sender, equals('USER'));
      expect(msg.content, equals('Estou com este erro na tela'));
      expect(msg.imageUrl, equals('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA'));
    });
  });
}
