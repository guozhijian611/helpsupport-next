import 'package:flutter/material.dart';

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

Future<ChatLaunchOption?> showChatLaunchSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<ChatLaunchOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ChatLaunchSheet(title: title),
  );
}

enum ChatLaunchOption { online, local }

class _ChatLaunchSheet extends StatelessWidget {
  const _ChatLaunchSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7EC),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _t(context, '模式选择', 'Mode selection'),
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF96999F),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _LaunchOptionCard(
                      title: _t(context, '在线模式', 'Online mode'),
                      subtitle: _t(
                        context,
                        '使用云端模型聊天',
                        'Use the online model conversation',
                      ),
                      colors: const [Color(0xFF79B4F6), Color(0xFF5D9CE9)],
                      icon: Icons.public_rounded,
                      onTap: () =>
                          Navigator.of(context).pop(ChatLaunchOption.online),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _LaunchOptionCard(
                      title: _t(context, '本地模式', 'Local mode'),
                      subtitle: _t(
                        context,
                        '使用本地模型聊天',
                        'Use the on-device local model',
                      ),
                      colors: const [Color(0xFFFFC66D), Color(0xFFFFB04A)],
                      icon: Icons.home_rounded,
                      onTap: () =>
                          Navigator.of(context).pop(ChatLaunchOption.local),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchOptionCard extends StatelessWidget {
  const _LaunchOptionCard({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          height: 196,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: colors),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFFDF9F6),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _t(context, '进入', 'Enter'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(icon, color: Colors.white, size: 46),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
