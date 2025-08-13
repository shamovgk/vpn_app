// lib/features/about/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';
import 'package:vpn_app/ui/widgets/app_custom_appbar.dart';
import 'package:vpn_app/ui/widgets/themed_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    return ThemedScaffold(
      appBar: const AppCustomAppBar(title: 'О приложении'),
      body: Center(
        child: SingleChildScrollView(
          padding: t.spacing.all(t.spacing.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: t.spacing.md,
                    horizontal: t.spacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: c.bgLight,
                    borderRadius: t.radii.brXl,
                    boxShadow: t.shadows.z1,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/about_icon.png',
                        width: 128,
                        height: 128,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: t.spacing.md),
                      Text(
                        'UgbuganVPN',
                        textAlign: TextAlign.center,
                        style: t.typography.h2.copyWith(
                          color: c.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: t.spacing.md),
                      Text(
                        'UgbuganVPN — это про надёжность, скорость и колорит!',
                        textAlign: TextAlign.center,
                        style: t.typography.body.copyWith(
                          color: c.textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: t.spacing.md),

                // Info card
                Card(
                  color: c.bgLight,
                  shape: RoundedRectangleBorder(borderRadius: t.radii.brLg),
                  child: Padding(
                    padding: t.spacing.all(t.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Версия',
                          textAlign: TextAlign.center,
                          style: t.typography.h3.copyWith(
                            color: c.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: t.spacing.xxs),
                        Text(
                          '1.0.0',
                          textAlign: TextAlign.center,
                          style: t.typography.body.copyWith(
                            color: c.textMuted,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: t.spacing.sm),
                        Text(
                          'Разработчики',
                          textAlign: TextAlign.center,
                          style: t.typography.h3.copyWith(
                            color: c.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: t.spacing.xxs),
                        Text(
                          'Абдурахманов Гасан\nШамов Гаджикурбан',
                          textAlign: TextAlign.center,
                          style: t.typography.body.copyWith(
                            color: c.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: t.spacing.lg),

                // Social / links row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.email, color: c.primary, size: 32),
                      tooltip: 'Почта',
                      onPressed: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'support@vpnapp.com',
                          query: 'subject=Обращение через приложение',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    SizedBox(width: t.spacing.lg),
                    IconButton(
                      icon: Icon(Icons.language, color: c.primary, size: 32),
                      tooltip: 'Сайт',
                      onPressed: () async {
                        final uri = Uri.parse('https://ugbuganvpn.com');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    SizedBox(width: t.spacing.lg),
                    IconButton(
                      icon: Icon(Icons.telegram, color: c.primary, size: 32),
                      tooltip: 'Telegram',
                      onPressed: () async {
                        final uri = Uri.parse('https://t.me/ugbuganvpn');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),

                SizedBox(height: t.spacing.md),

                // Privacy link
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('https://ugbuganvpn.com/privacy');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      'Политика конфиденциальности',
                      style: t.typography.body.copyWith(
                        color: c.primary,
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
      ),
    );
  }
}
