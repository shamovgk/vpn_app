# Contributing to VPN App

Thank you for considering contributing to VPN App!  
This document outlines the process for contributing to the project, including development workflow, code standards, server administration, deployment, and VPN integration.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Branching Strategy and Git Workflow](#branching-strategy-and-git-workflow)
- [Workflow](#workflow)
- [Code Style and Testing](#code-style-and-testing)
- [Reporting Issues](#reporting-issues)
- [Working with the Server (Node.js/Express)](#working-with-the-server-nodejsexpress)
- [Working with the Server via VSCode Remote - SSH](#working-with-the-server-vscode-remote---ssh)
- [Server Administration and PM2](#server-administration-and-pm2)
- [WireGuard: Installation and Integration](#wireguard-installation-and-integration)
- [FAQ](#faq)

---

## Getting Started

- Fork the repository on GitHub.
- Clone your fork:
  ```bash
  git clone https://github.com/<your-username>/vpn_app.git
  cd vpn_app
  ```

* Install dependencies:

  * For Flutter client:

    ```bash
    flutter pub get
    ```
  * For server (if separated):

    ```bash
    cd server
    npm install
    ```
* Ensure your environment matches the requirements (see README.md).
* Do not commit credentials, private keys, secrets, or configuration files containing secrets.

---

## Branching Strategy and Git Workflow

* Work only in isolated branches. Do not commit directly to `main`.
* Branch types:

  * `feature/<desc>` — new features (e.g., `feature/payment-integration`)
  * `bugfix/<desc>` — bug fixes (e.g., `bugfix/login-error`)
  * `docs/<desc>` — documentation updates (e.g., `docs/update-readme`)
  * `hotfix/<desc>` — urgent fixes (e.g., `hotfix/server-crash`)
* Branch naming: use descriptive, hyphen-separated names.

**Example:**

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature
```

Make commits with clear messages:

```bash
git add .
git commit -m "Add payment screen and YooKassa integration"
git push origin feature/your-feature
```

---

## Workflow

* **Always update main before starting:**

  ```bash
  git checkout main
  git pull origin main
  ```
* **Create a new branch for your task.**
* **Write and test your code locally (or on the server for backend).**
* **Write tests (unit/widget for Flutter; npm test for Node.js).**
* **Push your branch to GitHub and create a Pull Request (PR) to `main`:**

  * Provide a clear title and description.
  * Reference related issues (e.g., `Fixes #123`).
  * Ensure all CI checks pass.
* **Address reviewer feedback. One approval is required to merge.**
* **After merging, update main and delete your branch:**

  ```bash
  git checkout main
  git pull origin main
  git branch -d feature/your-feature
  ```

### Resolving Merge Conflicts

* If conflicts occur:

  ```bash
  git add <file>
  git commit
  git push origin feature/your-feature
  ```

---

## Code Style and Testing

* **Flutter:**

  * Follow the [Flutter style guide](https://dart.dev/effective-dart/style).
  * Before committing:

    ```bash
    flutter format .
    flutter analyze
    flutter test
    ```
  * Aim for >80% test coverage.
* **Node.js/Express:**

  * Use ESLint:

    ```bash
    npm run lint
    ```
  * Write tests for main functions and API endpoints.

---

## Reporting Issues

* Use the GitHub Issues tracker to report bugs or request features.
* Provide a clear title and description.
* Include reproduction steps (for bugs) or a detailed proposal (for features).
* Check for existing issues to avoid duplicates.

---

## Working with the Server (Node.js/Express)

* The server logic is in the `server/` folder.
* Main commands:

  ```bash
  cd server
  npm install
  npm start
  pm2 start index.js --name vpn-server
  ```
* The `.env` file must be created from `.env.example` and **must NOT be committed to git**.

---

## Working with the Server via VSCode Remote - SSH

You can develop, deploy, and debug directly on your Ubuntu server using [VSCode Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh):

1. **Install the Remote - SSH extension in VSCode.**
2. **Set up SSH access (key-based preferred).**
3. **Open the command palette (Ctrl+Shift+P) → Remote-SSH: Connect to Host... → Enter your server.**
4. **In the new VSCode window, open your project directory on the server (e.g., `/home/ubuntu/vpn-server`).**
5. **Edit files, use the integrated terminal, and manage your server as if working locally.**
6. **Run git commands (`add`, `commit`, `push`, `pull`) directly on the server in VSCode.**
7. **You can keep two VSCode windows open:**

   * One local for the Flutter client.
   * One remote for the Node.js server.
8. **After making changes:**

   * Commit and push on the server, then pull locally (or vice versa).
   * All changes are synchronized through git.

**Initial deployment:**

* If there is no project on the server, clone it:

  ```bash
  git clone https://github.com/<your-username>/vpn_app.git
  cd vpn_app
  npm install
  ```
* Then open this folder via Remote - SSH in VSCode.

---

## Server Administration and PM2

Node.js server is usually managed by [pm2](https://pm2.keymetrics.io/):

* List pm2 processes:

  ```bash
  pm2 list
  ```
* Stop server:

  ```bash
  pm2 stop vpn-server
  ```
* Delete process:

  ```bash
  pm2 delete vpn-server
  ```
* Install dependencies:

  ```bash
  npm install
  ```
* View logs:

  ```bash
  pm2 logs vpn-server
  ```

### Common File Maintenance Tasks

* Remove unnecessary files (e.g., node\_modules, package-lock.json, index.js):

  ```bash
  rm -rf node_modules package-lock.json index.js
  ```
* View all files (including hidden):

  ```bash
  ls -la
  ```
* Add new files (from Windows, for example):

  ```bash
  scp -r path-to-file\index.js user@server-ip:~/project-directory/
  ```

---

## WireGuard: Installation and Integration

WireGuard is required for the VPN server functionality.

### Prerequisites

* Ubuntu 20.04/22.04 with a public IP
* SSH access (root or sudo privileges)
* Port 51820/udp open on the firewall/provider
* `/root/vpn-server/` directory containing `generate_vpn_key.sh` and `add_to_wg_conf.sh` scripts

### Setup Steps

1. **Update system:**

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
2. **Install WireGuard:**

   ```bash
   sudo apt install wireguard wireguard-tools -y
   ```
3. **Generate server keys:**

   ```bash
   wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
   ```

   * Private key: `/etc/wireguard/privatekey`
   * Public key: `/etc/wireguard/publickey`
   * Update the `serverPublicKey` in the `/get-vpn-config` API with this key.
4. **Edit `/etc/wireguard/wg0.conf`:**

   ```
   [Interface]
   PrivateKey = <Your_Server_Private_Key>
   Address = 10.0.0.1/24
   ListenPort = 51820
   PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
   ```

   * Replace `<Your_Server_Private_Key>` accordingly.
   * Ensure `eth0` matches your main network interface (`ip a`).
5. **Firewall and IP forwarding:**

   ```bash
   sudo ufw allow 51820/udp
   sudo sysctl -w net.ipv4.ip_forward=1
   sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
   ```
6. **Make scripts executable:**

   ```bash
   sudo chmod +x /root/vpn-server/generate_vpn_key.sh
   sudo chmod +x /root/vpn-server/add_to_wg_conf.sh
   ```
7. **Start WireGuard:**

   ```bash
   sudo wg-quick up wg0
   sudo systemctl enable wg-quick@wg0
   ```
8. **Check WireGuard status:**

   ```bash
   sudo wg show
   ```
9. **Logs:**

   ```bash
   journalctl -u wg-quick@wg0
   ```

---

## Testing

* Register a new user via the `/register` endpoint, verify email, and ensure a VPN key is generated and added to `wg0.conf`.
* Test API with:

  ```bash
  curl -X POST -H "Content-Type: application/json" -d '{"username":"testuser","password":"testpass123","email":"test@example.com"}' http://localhost:3000/register
  ```
* Connect a client and ensure WireGuard is working:

  * New clients should appear in `sudo wg show`.
  * Verify IPs and keys are added correctly.

---

## FAQ

### How do I connect to the server and work with code?

See [Working with the Server via VSCode Remote - SSH](#working-with-the-server-vscode-remote---ssh).

### How do I push changes made on the server back to GitHub?

Use `git add/commit/push` on the server (via SSH or VSCode Remote). Locally, use `git pull`.
All changes sync via git.

### How do I troubleshoot WireGuard issues?

* Ensure port 51820/udp is open (`sudo ufw status`).
* Verify correct keys and configuration.
* Use logs: `journalctl -u wg-quick@wg0`, `sudo wg show`.

### How do I restart the Node.js server?

```bash
pm2 restart vpn-server
```

or

```bash
pm2 reload vpn-server
```

### How do I recover after a server crash?

* Check logs: `pm2 logs vpn-server`, `journalctl`
* Restart with pm2.
* Verify the SQLite DB.

---

If you have questions or need help, create an issue or contact the team.
Thank you for contributing to VPN App!