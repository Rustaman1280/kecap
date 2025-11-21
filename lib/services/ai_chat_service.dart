import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/ai_message.dart';

class AiChatService {
  AiChatService._();

  static final AiChatService instance = AiChatService._();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _modelName = 'gemini-2.0-flash';

  GenerativeModel get _model {
    if (_apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY belum diatur.');
    }
    return GenerativeModel(model: _modelName, apiKey: _apiKey);
  }

  Future<String> sendMessage({required List<AiMessage> history, required String prompt}) async {
    final chat = _model.startChat(
      history: history
          .map(
            (msg) => Content(
              msg.isUser ? 'user' : 'model',
              [TextPart(msg.text)],
            ),
          )
          .toList(),
    );
    final response = await chat.sendMessage(Content.text(prompt));
    return response.text?.trim() ?? 'Maaf, aku belum bisa menjawabnya.';
  }
}
