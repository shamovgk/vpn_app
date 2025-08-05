import 'package:flutter/material.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: 
          Text(
            "О приложении",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.text, 
              fontWeight: FontWeight.w700,
              ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.bgLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/about_icon.png', // Укажи путь к своему PNG-логотипу
                      width: 128,
                      height: 128,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "UgbuganVPN",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "UgbuganVPN — это про надёжность, скорость и колорит!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Card(
                color: colors.bgLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Центрируем всё
                    children: [
                      Text(
                        "Версия",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "1.0.0",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        "Разработчики",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Абдурахманов Гасан\n Шамов Гаджикурбан", // Впиши реальные имена или команду
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // ===== КОНТАКТНЫЕ КНОПКИ =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email
                  IconButton(
                    icon: Icon(Icons.email, color: colors.primary, size: 32),
                    tooltip: "Почта",
                    onPressed: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'support@vpnapp.com', // Замени на свою почту
                        query: 'subject=Обращение через приложение',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                  const SizedBox(width: 24),

                  // Website
                  IconButton(
                    icon: Icon(Icons.language, color: colors.primary, size: 32),
                    tooltip: "Сайт",
                    onPressed: () async {
                      final uri = Uri.parse('https://ugbuganvpn.com');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const SizedBox(width: 24),

                  // Telegram
                  IconButton(
                    icon: Icon(Icons.telegram, color: colors.primary, size: 32),
                    tooltip: "Telegram",
                    onPressed: () async {
                      final uri = Uri.parse('https://t.me/ugbuganvpn');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ =====
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('https://ugbuganvpn.com/privacy'); // Замени на свой url
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    "Политика конфиденциальности",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
