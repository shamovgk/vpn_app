import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.fitWidth,
          opacity: 0.7,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'О нас',
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 20),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyMedium?.color),
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
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
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
                          child: Icon(FontAwesomeIcons.telegram, size: 30, color: theme.textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                          child: Icon(FontAwesomeIcons.github, size: 30, color: theme.textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                          child: Icon(FontAwesomeIcons.globe, size: 30, color: theme.textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                          child: Icon(FontAwesomeIcons.envelope, size: 30, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Версия
                    Text(
                      'Версия: 1.0.0',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Политика конфиденциальности
                    InkWell(
                      onTap: () => _launchURL(Uri.parse('https://github.com/shamovgk')),
                      child: Text(
                        'Политика конфиденциальности',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: theme.colorScheme.primary,
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

  // Функция для открытия URL
  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Не удалось открыть $url';
    }
  }
}