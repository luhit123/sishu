import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/parenting_tip.dart';
import '../models/app_language.dart';

/// Service for GPT-4o API interactions
/// Used by MonaAI for chat and Tips Management for content generation
class GPTService {
  static GPTService? _instance;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _dalleUrl =
      'https://api.openai.com/v1/images/generations';
  static const String _model = 'gpt-4o';

  factory GPTService() {
    _instance ??= GPTService._internal();
    return _instance!;
  }

  GPTService._internal();

  // ============================================================================
  // API KEY MANAGEMENT
  // ============================================================================

  /// Get the API key from .env
  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  /// Check if API key is configured (not placeholder)
  bool get hasApiKey {
    final key = _apiKey;
    return key != null &&
        key.isNotEmpty &&
        key != 'your_openai_api_key_here' &&
        key.startsWith('sk-');
  }

  // ============================================================================
  // CORE API CALL
  // ============================================================================

  /// Make a GPT-4o API call
  Future<String> _callGPT({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    if (!hasApiKey) {
      throw GPTException(
          'API key not configured. Please add your OpenAI API key to the .env file.');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else if (response.statusCode == 401) {
        throw GPTException(
            'Invalid API key. Please check your OpenAI API key in .env file.');
      } else if (response.statusCode == 429) {
        throw GPTException('Rate limit exceeded. Please try again later.');
      } else {
        final error = jsonDecode(response.body);
        throw GPTException(error['error']?['message'] ?? 'API call failed');
      }
    } catch (e) {
      if (e is GPTException) rethrow;
      throw GPTException('Network error: ${e.toString()}');
    }
  }

  // ============================================================================
  // IMAGE GENERATION (DALL-E)
  // ============================================================================

  /// Generate an image using DALL-E
  Future<String> generateImage({
    required String prompt,
    String size = '1024x1024',
  }) async {
    if (!hasApiKey) {
      throw GPTException('API key not configured.');
    }

    try {
      final response = await http.post(
        Uri.parse(_dalleUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': size,
          'quality': 'standard',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'][0]['url'] as String;
      } else if (response.statusCode == 401) {
        throw GPTException('Invalid API key.');
      } else if (response.statusCode == 429) {
        throw GPTException('Rate limit exceeded. Please try again later.');
      } else {
        final error = jsonDecode(response.body);
        throw GPTException(
            error['error']?['message'] ?? 'Image generation failed');
      }
    } catch (e) {
      if (e is GPTException) rethrow;
      throw GPTException('Image generation error: ${e.toString()}');
    }
  }

  // ============================================================================
  // MONA AI CHAT
  // ============================================================================

  /// Get a chat response from Mona AI
  Future<String> chat({
    required String userMessage,
    List<Map<String, String>> conversationHistory = const [],
    AppLanguage language = AppLanguage.english,
  }) async {
    final languageInstruction = language == AppLanguage.english
        ? 'Respond in English.'
        : 'IMPORTANT: You MUST respond in ${language.englishName} language using the ${language.script} script (${language.nativeName}). Write your entire response in ${language.script} script, not in English or transliteration.';

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            '''You are Mona, an AI pediatric care assistant for XoruCare (an Indian parenting and child health app).

Primary goal:
Sound highly human, like a calm and experienced pediatric doctor speaking to a worried parent.

Voice and bedside manner:
- Warm, compassionate, and confident
- Conversational and natural, never robotic
- Use plain language first; briefly explain medical terms if needed
- Reassure without dismissing concerns
- Ask 2-3 short leading questions in a natural doctor-like way before giving full guidance
- Use emojis sparingly (0-1 max), only when it helps warmth

Clinical communication style (important):
- Start with a short empathy line
- Then ask 2-3 focused leading questions to gather context (age, duration, severity, associated symptoms)
- Give clear, practical next steps in priority order
- Mention what to monitor over the next few hours
- Include red flags and when to seek urgent care
- End with a supportive closing line

Safety rules:
- Do NOT claim to be a licensed doctor or that this is a diagnosis
- Do NOT provide definitive diagnosis; provide likely possibilities and guidance
- For emergencies or red-flag symptoms, explicitly advise immediate in-person/ER care
- If child age is critical and missing, ask for age (especially infants under 3 months)

Domain focus:
- Baby and child health
- Nutrition/feeding (including Indian foods and routines)
- Sleep and behavior
- Development milestones
- Vaccinations and common childhood illnesses

Scope guard (strict):
- Only answer questions related to parenting, babies, children, pediatric health, child nutrition, child sleep, development, vaccination, or caregiver guidance.
- If the user asks anything outside this scope (coding, politics, adult medicine, finance, entertainment, general trivia, etc.), do NOT answer that topic.
- For out-of-scope queries, give a brief polite refusal in 1-2 lines and redirect to child/parenting topics.
- Do not provide partial out-of-scope answers.

Response constraints:
- Keep answers concise but useful (typically 90-170 words)
- Use plain text only with clean sentences; no markdown
- Do not use asterisks, hash symbols, or decorative formatting characters
- Avoid bullet symbols and special list markers; if needed use simple numbered lines like 1. 2. 3.
- Avoid generic filler and repetitive disclaimers

$languageInstruction'''
      },
      ...conversationHistory,
      {'role': 'user', 'content': userMessage},
    ];

    final rawResponse = await _callGPT(
      messages: messages,
      temperature: 0.8,
      maxTokens: 650,
    );
    return _sanitizeChatResponse(rawResponse);
  }

  /// Translate short UI prompt phrases to the selected language.
  /// Returns output in the same order and count as input phrases.
  Future<List<String>> translateQuickPrompts({
    required List<String> phrases,
    required AppLanguage language,
  }) async {
    if (language == AppLanguage.english || phrases.isEmpty) {
      return phrases;
    }

    // Translate in chunks to avoid response truncation on larger prompt sets.
    const chunkSize = 12;
    final translatedAll = <String>[];

    for (var start = 0; start < phrases.length; start += chunkSize) {
      final end = (start + chunkSize > phrases.length)
          ? phrases.length
          : start + chunkSize;
      final chunk = phrases.sublist(start, end);

      final response = await _callGPT(
        messages: [
          {
            'role': 'system',
            'content':
                '''You are a translation engine for short mobile UI prompts.
Translate each input phrase to ${language.englishName} using ${language.script} script (${language.nativeName}).
Rules:
- Keep meaning natural and parent-friendly.
- Keep each phrase concise.
- Return ONLY valid JSON array of strings.
- Keep same order and same number of items as input.
- No markdown, no extra keys, no explanations.''',
          },
          {
            'role': 'user',
            'content': jsonEncode(chunk),
          },
        ],
        temperature: 0.2,
        maxTokens: 1800,
      );

      final translatedChunk = _parseTranslatedPromptArray(response);
      if (translatedChunk.length != chunk.length ||
          translatedChunk.any((text) => text.isEmpty)) {
        throw GPTException('Failed to translate quick prompts.');
      }
      translatedAll.addAll(translatedChunk);
    }

    if (translatedAll.length == phrases.length) {
      return translatedAll;
    }
    throw GPTException('Failed to translate quick prompts.');
  }

  List<String> _parseTranslatedPromptArray(String response) {
    var cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final decoded = jsonDecode(cleaned);
    if (decoded is List) {
      return decoded.map((e) => e.toString().trim()).toList(growable: false);
    }
    throw GPTException('Failed to parse translated prompt array.');
  }

  String _sanitizeChatResponse(String text) {
    return text
        // Remove markdown emphasis and heading markers.
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('`', '')
        // Normalize common bullet styles at line start.
        .replaceAllMapped(
          RegExp(r'^\s*[•\-–]+\s*', multiLine: true),
          (_) => '',
        )
        // Clean excessive blank lines.
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  // ============================================================================
  // PARENTING TIP GENERATION
  // ============================================================================

  /// Generate a parenting tip based on category and age group
  /// If customPrompt is provided, it will be used to guide the content generation
  Future<GeneratedTip> generateTip({
    required TipCategory category,
    required AgeGroup ageGroup,
    AppLanguage language = AppLanguage.english,
    ImageStyle imageStyle = ImageStyle.realistic,
    String? customPrompt,
  }) async {
    final languageInstruction = language == AppLanguage.english
        ? 'Write the content in English.'
        : '''IMPORTANT: Write ALL content (title, summary, content, and tags) in ${language.englishName} language using the ${language.script} script (${language.nativeName}).
Do NOT use English or transliteration. Use proper ${language.script} script characters throughout.''';

    // Use custom prompt if provided, otherwise generate default topic
    final topicInstruction = customPrompt != null && customPrompt.isNotEmpty
        ? '''Generate a helpful parenting tip based on this specific request: "$customPrompt"

Category context: ${category.displayName}
Target age group: ${ageGroup.displayName}'''
        : '''Generate a helpful parenting tip for Indian parents about "${category.displayName}" for children in the "${ageGroup.displayName}" age group.''';

    final prompt = '''$topicInstruction

$languageInstruction

Respond ONLY with a valid JSON object (no markdown, no explanation) in this exact format:
{
  "title": "An engaging, specific title (max 60 characters)",
  "summary": "A brief 1-sentence summary (max 100 characters)",
  "content": "Detailed, helpful content with practical advice. Include specific tips, examples, and actionable steps. Write 3-4 paragraphs. Be culturally relevant to Indian parents where applicable.",
  "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"],
  "readTimeMinutes": 3
}

Requirements:
- Title should be catchy and specific
- Content should be informative, practical, and encouraging
- Include Indian-specific advice where relevant (foods, practices, etc.)
- Tags should be relevant keywords (5 tags)
- Read time should be realistic (2-5 minutes based on content length)
- Content should be original and helpful''';

    final response = await _callGPT(
      messages: [
        {
          'role': 'system',
          'content':
              'You are a pediatric health expert and parenting advisor. Respond only with valid JSON.'
        },
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.8,
      maxTokens: 1500,
    );

    try {
      // Clean the response (remove markdown code blocks if present)
      String cleanedResponse = response.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse =
            cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      final json = jsonDecode(cleanedResponse) as Map<String, dynamic>;

      return GeneratedTip(
        title: json['title'] as String,
        summary: json['summary'] as String,
        content: json['content'] as String,
        tags: (json['tags'] as List).cast<String>(),
        readTimeMinutes: json['readTimeMinutes'] as int,
        imageUrl: null, // Image generation is now manual
      );
    } catch (e) {
      if (e is GPTException) rethrow;
      throw GPTException('Failed to parse generated tip: ${e.toString()}');
    }
  }

  /// Generate multiple tips at once
  Future<List<GeneratedTip>> generateMultipleTips({
    required TipCategory category,
    required AgeGroup ageGroup,
    AppLanguage language = AppLanguage.english,
    int count = 3,
  }) async {
    final tips = <GeneratedTip>[];
    for (int i = 0; i < count; i++) {
      final tip = await generateTip(
        category: category,
        ageGroup: ageGroup,
        language: language,
      );
      tips.add(tip);
    }
    return tips;
  }
}

// ============================================================================
// MODELS
// ============================================================================

/// Image style options for tip generation
enum ImageStyle {
  realistic('Realistic',
      'Ultra-realistic, high-quality photograph. Modern, warm lighting, natural colors, professional photography, candid family moment. Cinematic composition, shallow depth of field, 8K quality, photorealistic.'),
  cartoon('Cartoon',
      'Colorful cartoon illustration style. Friendly characters, bold outlines, vibrant colors, playful and fun atmosphere. Pixar-style 3D cartoon look, expressive faces, cheerful mood.'),
  anime('Anime',
      'Beautiful anime/manga art style. Soft shading, expressive eyes, detailed backgrounds, Studio Ghibli inspired. Warm and heartfelt atmosphere, elegant line work.'),
  watercolor('Watercolor',
      'Soft watercolor painting style. Gentle pastel colors, artistic brush strokes, dreamy and peaceful atmosphere. Delicate details, flowing colors, artistic and elegant.'),
  flatDesign('Flat Design',
      'Modern flat design illustration. Clean geometric shapes, bold colors, minimalist style. Contemporary vector art, simple and elegant, trendy design.'),
  threeD('3D Render',
      'High-quality 3D rendered image. Soft lighting, realistic textures, modern CGI style. Octane render quality, detailed materials, professional 3D artwork.'),
  vintage('Vintage',
      'Warm vintage photography style. Nostalgic feel, soft sepia tones, retro atmosphere. Film grain texture, classic composition, timeless and cozy mood.'),
  futuristic('Futuristic',
      'Modern futuristic style. Sleek design, cool color palette, high-tech atmosphere. Clean lines, innovative feel, contemporary and forward-looking.');

  final String displayName;
  final String promptStyle;

  const ImageStyle(this.displayName, this.promptStyle);
}

/// Generated tip from GPT
class GeneratedTip {
  final String title;
  final String summary;
  final String content;
  final List<String> tags;
  final int readTimeMinutes;
  final String? imageUrl;

  GeneratedTip({
    required this.title,
    required this.summary,
    required this.content,
    required this.tags,
    required this.readTimeMinutes,
    this.imageUrl,
  });
}

/// Custom exception for GPT errors
class GPTException implements Exception {
  final String message;
  GPTException(this.message);

  @override
  String toString() => message;
}
