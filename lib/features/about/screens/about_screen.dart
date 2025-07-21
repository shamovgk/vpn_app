import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpn_app/ui/theme/app_colors.dart';
import 'package:vpn_app/ui/widgets/themed_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'О нас',
            style: TextStyle(fontSize: 20, color: colors.text, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Основная часть: Логотип и описание
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/tray_icon_connect.png',
                      height: 50,
                      width: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'UgbuganVPN — обеспечит вашу конфиденциальность и свободу в сети. Мы работаем над улучшением сервиса каждый день',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textMuted, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            // Футер
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ссылки на контакты
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                          child: Icon(FontAwesomeIcons.telegram, size: 30, color: colors.textMuted),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                          child: Icon(FontAwesomeIcons.github, size: 30, color: colors.textMuted),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                          child: Icon(FontAwesomeIcons.globe, size: 30, color: colors.textMuted),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                          child: Icon(FontAwesomeIcons.envelope, size: 30, color: colors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Версия
                    Text(
                      'Версия: 1.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textMuted.withAlpha(153), // 0.6 * 255 = 153
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Политика конфиденциальности
                    InkWell(
                      onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                      child: Text(
                        'Политика конфиденциальности',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Не удалось открыть $url';
    }
  }
}
