import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/ai_message.dart';

class AiChatService {
  AiChatService._();

  static final AiChatService instance = AiChatService._();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _modelName = 'models/gemini-flash-latest';
  static const String _systemPrompt =
      'Anda adalah teman belajar bahasa Inggris untuk remaja. Balaslah dengan bahasa indonesia campur inggris sedilit yang ramah, alami, dan sedikit humor. Jaga jawaban tetap ringkas untuk aplikasi seluler, hindari poin-poin dan nada formal. Tetap pada topik yang dibahas sebelumnya dan jaga percakapan tetap mengalir. Dorong dan koreksi dengan lembut, tetapi jangan pernah memberi ceramah.';

  GenerativeModel get _model {
    if (_apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY belum diatur.');
    }
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content(
        'system',
        [TextPart(_systemPrompt)],
      ),
    );
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
