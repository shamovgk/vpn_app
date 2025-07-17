# Участие в разработке VPN App

Спасибо, что хотите внести вклад в VPN App!  
Этот документ описывает процесс участия в проекте: рабочий процесс, стандарты, администрирование сервера, деплой и интеграцию WireGuard.

---

## Содержание

- [Начало работы](#начало-работы)
- [Стратегия ветвления и git workflow](#стратегия-ветвления-и-git-workflow)
- [Рабочий процесс](#рабочий-процесс)
- [Стиль кода и тестирование](#стиль-кода-и-тестирование)
- [Сообщение об ошибках](#сообщение-об-ошибках)
- [Работа с сервером (Node.js/Express)](#работа-с-сервером-nodejsexpress)
- [Работа с сервером через VSCode Remote - SSH](#работа-с-сервером-через-vscode-remote---ssh)
- [Администрирование сервера и PM2](#администрирование-сервера-и-pm2)
- [WireGuard: установка и интеграция](#wireguard-установка-и-интеграция)
- [Тестирование](#тестирование)
- [FAQ](#faq)

---

## Начало работы

- Сделайте форк репозитория на GitHub.
- Клонируйте свой форк:
  ```bash
  git clone https://github.com/<ваш-username>/vpn_app.git
  cd vpn_app
  ```

* Установите зависимости:

  * Для Flutter-клиента:

    ```bash
    flutter pub get
    ```
  * Для серверной части (если вынесена отдельно):

    ```bash
    cd server
    npm install
    ```
* Убедитесь, что ваша среда соответствует требованиям (см. README.md).
* Не коммитьте учетные данные, приватные ключи, секреты и конфиги с ними.

---

## Стратегия ветвления и git workflow

* Работайте только в изолированных ветках. Не коммитьте напрямую в `main`.
* Типы веток:

  * `feature/<описание>` — новые функции (например, `feature/payment-integration`)
  * `bugfix/<описание>` — исправления багов (например, `bugfix/login-error`)
  * `docs/<описание>` — изменения в документации (например, `docs/update-readme`)
  * `hotfix/<описание>` — срочные фиксы (например, `hotfix/server-crash`)
* Ветка должна иметь осмысленное имя с дефисами.

**Пример:**

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature
```

Делайте коммиты с понятными сообщениями:

```bash
git add .
git commit -m "Добавлен экран оплаты и интеграция с YooKassa"
git push origin feature/your-feature
```

---

## Рабочий процесс

* **Перед началом работы всегда обновляйте main:**

  ```bash
  git checkout main
  git pull origin main
  ```
* **Создайте отдельную ветку для задачи.**
* **Пишите и тестируйте код локально (или на сервере для backend).**
* **Покрывайте изменения тестами (unit/widget для Flutter, npm test для Node.js).**
* **Пушьте ветку и создавайте Pull Request (PR) в main:**

  * Дайте понятный заголовок и описание.
  * Привяжите к issue, если есть (например, `Fixes #123`).
  * Убедитесь, что все проверки CI проходят.
* **Исправьте замечания ревьюеров. Для слияния требуется хотя бы один аппрув.**
* **После слияния обновите main и удалите рабочую ветку:**

  ```bash
  git checkout main
  git pull origin main
  git branch -d feature/your-feature
  ```

### Разрешение конфликтов слияния

Если возникли конфликты:

```bash
git add <файл>
git commit
git push origin feature/your-feature
```

---

## Стиль кода и тестирование

* **Flutter:**

  * Следуйте [гайду Effective Dart](https://dart.dev/effective-dart/style).
  * Перед коммитом выполните:

    ```bash
    flutter format .
    flutter analyze
    flutter test
    ```
  * Старайтесь поддерживать покрытие тестами >80%.
* **Node.js/Express:**

  * Используйте ESLint:

    ```bash
    npm run lint
    ```
  * Пишите тесты для основных функций и API.

---

## Сообщение об ошибках

* Используйте GitHub Issues для сообщений о багах и запросов фич.
* Давайте четкий заголовок и описание.
* Добавляйте шаги воспроизведения (для багов) или подробное предложение (для фич).
* Проверяйте, нет ли похожих issues.

---

## Работа с сервером (Node.js/Express)

* Серверная логика находится в папке `server/`.
* Основные команды:

  ```bash
  cd server
  npm install
  npm start
  pm2 start index.js --name vpn-server
  ```
* Файл `.env` должен быть создан из `.env.example` и **НЕ попадать в git**.

---

## Работа с сервером через VSCode Remote - SSH

Можно разрабатывать, деплоить и дебажить сервер прямо на Ubuntu с помощью [VSCode Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh):

1. **Установите расширение Remote - SSH в VSCode.**
2. **Настройте SSH-доступ (лучше с помощью ключей).**
3. **Откройте палитру команд (Ctrl+Shift+P) → Remote-SSH: Connect to Host... → выберите сервер.**
4. **В новом окне VSCode откройте папку с проектом на сервере (например, `/home/ubuntu/vpn-server`).**
5. **Редактируйте файлы, используйте терминал, управляйте сервером — всё, как локально.**
6. **Все git-команды (add, commit, push, pull) доступны прямо на сервере в VSCode.**
7. **Можно держать два окна VSCode:**

   * Локальное — для Flutter-клиента.
   * Удалённое — для Node.js сервера.
8. **После изменений:**

   * Делайте commit/push на сервере, затем pull локально (или наоборот).
   * Всё синхронизируется через git.

**Первое развертывание:**
Если проекта нет на сервере — клонируйте репозиторий:

```bash
git clone https://github.com/<ваш-username>/vpn_app.git
cd vpn_app
npm install
```

Затем откройте эту папку через Remote - SSH.

---

## Администрирование сервера и PM2

Node.js сервер обычно работает под [pm2](https://pm2.keymetrics.io/):

* Список процессов pm2:

  ```bash
  pm2 list
  ```
* Остановка сервера:

  ```bash
  pm2 stop vpn-server
  ```
* Удаление процесса:

  ```bash
  pm2 delete vpn-server
  ```
* Установка зависимостей:

  ```bash
  npm install
  ```
* Просмотр логов:

  ```bash
  pm2 logs vpn-server
  ```

### Часто используемые команды для файлов и деплоя

* Удалить лишние файлы (например, node\_modules, package-lock.json, index.js):

  ```bash
  rm -rf node_modules package-lock.json index.js
  ```
* Посмотреть все файлы (включая скрытые):

  ```bash
  ls -la
  ```
* Залить новые файлы с Windows:

  ```bash
  scp -r path-to-file\index.js user@server-ip:~/project-directory/
  ```

---

## WireGuard: установка и интеграция

WireGuard необходим для работы VPN сервера.

### Предварительные требования

* Ubuntu 20.04/22.04 с публичным IP
* SSH-доступ (root или sudo)
* Открыт порт 51820/udp на фаерволе/у провайдера
* Каталог `/root/vpn-server/` со скриптами `generate_vpn_key.sh` и `add_to_wg_conf.sh`

### Шаги установки

1. **Обновить систему:**

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
2. **Установить WireGuard:**

   ```bash
   sudo apt install wireguard wireguard-tools -y
   ```
3. **Сгенерировать ключи сервера:**

   ```bash
   wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
   ```

   * Приватный ключ: `/etc/wireguard/privatekey`
   * Публичный ключ: `/etc/wireguard/publickey`
   * Внесите публичный ключ в API `/get-vpn-config`.
4. **Редактировать `/etc/wireguard/wg0.conf`:**

   ```
   [Interface]
   PrivateKey = <Ваш_приватный_ключ_сервера>
   Address = 10.0.0.1/24
   ListenPort = 51820
   PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
   ```

   * Замените `<Ваш_приватный_ключ_сервера>` на значение из файла.
   * Проверьте, что интерфейс `eth0` правильный (см. `ip a`).
5. **Открыть порт и включить IP-форвардинг:**

   ```bash
   sudo ufw allow 51820/udp
   sudo sysctl -w net.ipv4.ip_forward=1
   sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
   ```
6. **Дать права на выполнение скриптам:**

   ```bash
   sudo chmod +x /root/vpn-server/generate_vpn_key.sh
   sudo chmod +x /root/vpn-server/add_to_wg_conf.sh
   ```
7. **Запустить WireGuard:**

   ```bash
   sudo wg-quick up wg0
   sudo systemctl enable wg-quick@wg0
   ```
8. **Проверить статус WireGuard:**

   ```bash
   sudo wg show
   ```
9. **Логи:**

   ```bash
   journalctl -u wg-quick@wg0
   ```

---

## Тестирование

* Зарегистрируйте нового пользователя через `/register`, подтвердите email — проверьте генерацию ключа и добавление в `wg0.conf`.
* Пример теста API:

  ```bash
  curl -X POST -H "Content-Type: application/json" -d '{"username":"testuser","password":"testpass123","email":"test@example.com"}' http://localhost:3000/register
  ```
* Подключитесь клиентом, убедитесь в появлении клиента в `sudo wg show`.
* Проверьте корректность IP и ключей.

---

## FAQ

### Как подключиться к серверу и работать с кодом?

См. раздел ["Работа с сервером через VSCode Remote - SSH"](#работа-с-сервером-через-vscode-remote---ssh).

### Как отправить изменения, сделанные на сервере, в GitHub?

Используйте `git add/commit/push` на сервере (через ssh или Remote-SSH). Локально — `git pull`. Всё синхронизируется через git.

### Как отладить WireGuard?

* Проверьте открыт ли порт 51820/udp (`sudo ufw status`).
* Проверьте корректность ключей и конфигов.
* Логи: `journalctl -u wg-quick@wg0`, `sudo wg show`.

### Как перезапустить Node.js сервер?

```bash
pm2 restart vpn-server
```

или

```bash
pm2 reload vpn-server
```

### Как восстановить сервер после сбоя?

* Проверьте логи: `pm2 logs vpn-server`, `journalctl`
* Перезапустите через pm2.
* Проверьте базу данных SQLite.

---

Если возникли вопросы или требуется помощь — создайте issue или обратитесь к участникам команды.
Спасибо за вклад в развитие VPN App!
