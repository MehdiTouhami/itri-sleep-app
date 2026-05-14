import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/sleep_provider.dart';
import '../widgets/glass_card.dart';
import '../core/models/sleep_night.dart';
import '../core/services/ai_service.dart';
import '../core/utils/duration_utils.dart'; // still used by helper methods below

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  // Sends prompts to AI
  final AIService ai = AIService();

  // Controls text input
  final TextEditingController _controller = TextEditingController();

  // Controls chat scrolling
  final ScrollController _scrollController = ScrollController();

  // Stores chat messages
  final List<Map<String, String>> _messages = [];

  // Prevents double sending
  bool _isSending = false;

  // Quick prompt buttons
  final List<String> quickPrompts = const [
    "How can I improve deep sleep?",
    "Was my recovery good?",
    "What should I do tonight?",
    "How does caffeine affect sleep?",
  ];

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    // Clean up controllers
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(List<SleepNight> nights, String text) async {
    final message = text.trim();

    // Ignore empty message or sending while waiting
    if (message.isEmpty || _isSending) return;

    setState(() {
      // Add user message to chat
      _messages.add({"role": "user", "text": message});

      // Show loading state
      _isSending = true;
    });

    // Clear input after sending
    _controller.clear();

    // Scroll to newest message
    _scrollToBottom();

    // Build history from all complete [user, coach] pairs before this message
    final history = <List<String>>[];
    final previous = _messages.sublist(0, _messages.length - 1);
    for (int i = 0; i + 1 < previous.length; i += 2) {
      if (previous[i]['role'] == 'user' && previous[i + 1]['role'] == 'coach') {
        history.add([previous[i]['text'] ?? '', previous[i + 1]['text'] ?? '']);
      }
    }

    try {
      // RAG backend handles retrieval + context — just send the message
      final reply = await ai.sendMessage(message, history: history);

      if (!mounted) return;

      setState(() {
        // Add AI reply to chat
        _messages.add({"role": "coach", "text": reply});

        // Stop loading state
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        // Fallback message if backend is unreachable
        _messages.add({
          "role": "coach",
          "text": "Could not reach the sleep coach. Make sure the backend is running on localhost:8000.",
        });

        _isSending = false;
      });
    }

    // Scroll again after reply
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Keeps latest message visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(sleepDataProvider).when(
      loading: () => const Scaffold(body: SafeArea(child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading coach data:\n$e', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
      data: (nights) {
        if (nights.isEmpty) {
          return const Scaffold(
            backgroundColor: Color(0xFF050B16),
            body: SafeArea(
              child: Center(
                child: Text(
                  'No sleep data found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          );
        }

        // Main sleep values used in the UI
        final latest = nights.first;
        final averageScore = _averageScore(nights);
        final averageSleep = _averageSleepMinutes(nights);
        final trend = _trendValue(nights.take(7).toList());

        return Scaffold(
          backgroundColor: const Color(0xFF050B16),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF06152D),
                  Color(0xFF050B16),
                  Color(0xFF040913),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      children: [
                        // Screen header
                        Row(
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sleep Coach",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "AI guidance based on your sleep data",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22D3EE),
                                    Color(0xFF3B82F6),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Hero summary card
                        GlassCard(
                          radius: 24,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF0F1E3A).withOpacity(0.95),
                                  const Color(0xFF0A1224).withOpacity(0.92),
                                ],
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF22D3EE),
                                        Color(0xFF3B82F6),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.bedtime_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _heroTitle(latest),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _heroSubtitle(
                                          latest,
                                          averageScore,
                                          averageSleep,
                                          trend,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Key sleep stats section
                        const Text(
                          "Tonight's context",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.score_rounded,
                                iconColor: const Color(0xFF60A5FA),
                                title: "Sleep Score",
                                value: "${latest.sleepScore}",
                                subtitle: latest.quality,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.nightlight_round,
                                iconColor: const Color(0xFFA78BFA),
                                title: "Deep Sleep",
                                value: latest.deepSleep,
                                subtitle: _deepSleepSubtitle(latest),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.show_chart_rounded,
                                iconColor: const Color(0xFF22D3EE),
                                title: "HRV",
                                value: latest.hrv,
                                subtitle: _hrvSubtitle(latest),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.favorite_rounded,
                                iconColor: const Color(0xFFFB7185),
                                title: "Resting HR",
                                value: latest.restingHR,
                                subtitle: "From Garmin data",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Quick prompt chips
                        const Text(
                          "Ask quickly",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: quickPrompts
                              .map(
                                (prompt) => _PromptChip(
                                  label: prompt,
                                  onTap: () => _sendMessage(nights, prompt),
                                ),
                              )
                              .toList(),
                        ),

                        const SizedBox(height: 20),

                        // Default coach messages if chat is empty
                        if (_messages.isEmpty) ...[
                          _CoachBubble(
                            text: _coachIntroMessage(latest, trend),
                          ),
                          const SizedBox(height: 12),
                          _CoachBubble(
                            text: _coachTonightReply(latest, averageSleep),
                          ),
                        ] else ...[
                          // Shows user and AI chat bubbles
                          ..._messages.map((msg) {
                            final isUser = msg["role"] == "user";

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: isUser
                                  ? _UserBubble(text: msg["text"] ?? '')
                                  : _CoachBubble(text: msg["text"] ?? ''),
                            );
                          }),
                        ],

                        // Typing indicator while waiting for AI reply
                        if (_isSending) ...[
                          const SizedBox(height: 4),
                          const _TypingBubble(),
                        ],

                        const SizedBox(height: 12),

                        // Rule-based recommendation card
                        GlassCard(
                          radius: 22,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: const Color(0xFF22D3EE)
                                        .withOpacity(0.15),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb_rounded,
                                    color: Color(0xFF22D3EE),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Recommended action",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _recommendedAction(latest),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Static topic suggestions
                        const Text(
                          "Suggested topics",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),

                        const Row(
                          children: [
                            Expanded(
                              child: _TopicCard(
                                icon: Icons.coffee_rounded,
                                title: "Caffeine",
                                subtitle: "Timing and sleep impact",
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _TopicCard(
                                icon: Icons.fitness_center_rounded,
                                title: "Training",
                                subtitle: "Recovery and sleep balance",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(
                              child: _TopicCard(
                                icon: Icons.phone_iphone_rounded,
                                title: "Screen Time",
                                subtitle: "Pre-bed routine advice",
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _TopicCard(
                                icon: Icons.schedule_rounded,
                                title: "Bedtime",
                                subtitle: "Consistency and routine",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // Bottom input area
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF091327).withOpacity(0.92),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 58,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Center(
                              child: TextField(
                                controller: _controller,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "Ask your sleep coach...",
                                  hintStyle: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                ),

                                // Sends message when Enter is pressed
                                onSubmitted: (_) => _sendMessage(
                                  nights,
                                  _controller.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Send button
                        GestureDetector(
                          onTap: _isSending
                              ? null
                              : () => _sendMessage(nights, _controller.text),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF22D3EE),
                                  Color(0xFF3B82F6),
                                ],
                              ),
                            ),
                            child: Icon(
                              _isSending
                                  ? Icons.hourglass_top_rounded
                                  : Icons.send_rounded,
                              color: Colors.white,
                            ),
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
    );
  }

  static int _averageScore(List<SleepNight> nights) {
    // Calculates average sleep score
    if (nights.isEmpty) return 0;

    final total = nights.fold<int>(0, (sum, n) => sum + n.sleepScore);
    return (total / nights.length).round();
  }

  static int _averageSleepMinutes(List<SleepNight> nights) {
    // Calculates average sleep duration in minutes
    if (nights.isEmpty) return 0;

    final total = nights.fold<int>(
      0,
      (sum, n) => sum + durationToMinutes(n.sleepDuration),
    );
    return (total / nights.length).round();
  }

  static int _trendValue(List<SleepNight> nights) {
    // Simple trend: latest score - oldest score
    if (nights.length < 2) return 0;
    return nights.first.sleepScore - nights.last.sleepScore;
  }

  static String _heroTitle(SleepNight latest) {
    // Changes top message based on score
    if (latest.sleepScore >= 85) return 'Your sleep coach is impressed';
    if (latest.sleepScore >= 75) return 'Your sleep coach is ready';
    if (latest.sleepScore >= 65) {
      return 'Your sleep coach sees room to improve';
    }
    return 'Your sleep coach has recovery advice';
  }

  static String _heroSubtitle(
    SleepNight latest,
    int averageScore,
    int averageSleep,
    int trend,
  ) {
    // Summary text for hero card
    final trendText = trend > 0
        ? 'improving'
        : trend < 0
            ? 'slipping slightly'
            : 'staying stable';

    return 'Your latest sleep score is ${latest.sleepScore}, your recent average is $averageScore, and your sleep duration average is ${minutesToDuration(averageSleep)}. Your trend is $trendText.';
  }

  static String _deepSleepSubtitle(SleepNight latest) {
    // Labels deep sleep quality
    final minutes = durationToMinutes(latest.deepSleep);
    if (minutes >= 120) return 'Strong recovery';
    if (minutes >= 80) return 'Decent recovery';
    return 'Could improve';
  }

  static String _hrvSubtitle(SleepNight latest) {
    // Handles missing HRV values
    if (latest.hrv == '--' || latest.hrv.isEmpty) return 'Not available';
    return 'Latest recorded value';
  }

  static String _coachIntroMessage(SleepNight latest, int trend) {
    // Default AI intro message
    final trendText = trend > 0
        ? 'Recovery is trending upward.'
        : trend < 0
            ? 'Recovery has dipped slightly.'
            : 'Recovery has stayed steady.';

    return 'Based on your latest sleep, your score was ${latest.sleepScore} with ${latest.quality.toLowerCase()} quality. $trendText';
  }

  static String _coachTonightReply(SleepNight latest, int averageSleep) {
    // Default coaching suggestion before user asks anything
    final parts = <String>[];

    if (latest.sleepScore < 75) {
      parts.add('Try to protect an earlier bedtime tonight');
    } else {
      parts.add('Keep your bedtime close to your current routine');
    }

    if (averageSleep < 420) {
      parts.add('aim for a bigger sleep window');
    }

    parts.add('reduce screen exposure before bed');
    parts.add('avoid late caffeine');

    return '${parts.join(', ')}, and give yourself a calmer wind-down so recovery can improve.';
  }

  static String _recommendedAction(SleepNight latest) {
    // Rule-based recommendation card text
    if (latest.sleepScore < 70) {
      return 'Tonight, focus on a lighter evening, reduced stimulation, and an earlier sleep opportunity to help recovery rebound.';
    }
    if (latest.sleepScore < 80) {
      return 'Try a steady bedtime, lower evening stimulation, and a simple wind-down routine to improve consistency and sleep quality.';
    }
    return 'Protect what is already working: maintain a similar bedtime, keep the wind-down calm, and avoid habits that cut into sleep duration.';
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _MiniStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Reusable small stat card
    return GlassCard(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Reusable quick prompt button
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  final String text;

  const _CoachBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    // Bubble used for AI replies
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF22D3EE),
                Color(0xFF3B82F6),
              ],
            ),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCard(
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    // Shown while waiting for AI response
    return const _CoachBubble(
      text: "Thinking...",
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    // Bubble used for user messages
    return Row(
      children: [
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1D4ED8),
                  Color(0xFF2563EB),
                ],
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TopicCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Reusable topic suggestion card
    return GlassCard(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
