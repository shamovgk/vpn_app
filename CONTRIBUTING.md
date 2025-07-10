# Contributing to VPN App

Thank you for considering contributing to the VPN App! This document outlines the process for contributing to the project to ensure a smooth and consistent workflow.

## Getting Started
- Create a fork of the repository on GitHub.
- Clone your fork:
  ```bash
  git clone https://github.com/shamovgk/vpn_app.git
  cd vpn_app
  ```
- Install dependencies:
  ```bash
  flutter pub get
  ```
- Ensure your environment meets the requirements (see README.md).

## General Recommendations
- Work in an isolated branch and avoid direct changes to `main`.
- If you need help, create an issue with the `question` tag or reach out to team members.
- Store credentials (e.g., SSH keys or passwords) in a secure place and do not commit them to the repository.

## Reporting Issues
- Use the GitHub Issues tracker to report bugs or suggest features.
- Provide a clear title and description.
- Include steps to reproduce (for bugs) or a detailed proposal (for features).
- Check for existing issues to avoid duplicates.

## Branching Strategy
- The default branch is `main`.
- Create a new branch for each contribution:
  - `feature/<feature-name>` for new features (e.g., `feature/subscription-screen`).
  - `bugfix/<bug-description>` for bug fixes (e.g., `bugfix/login-error`).
  - `docs/<doc-update>` for documentation updates (e.g., `docs/update-readme`).
  - `hotfix/<issue-description>` for urgent fixes (e.g., `hotfix/vpn-connection`).
- Use descriptive, hyphen-separated names (e.g., `feature/add-vpn-protocol`).

## Workflow
- Start from the latest version of the `main` branch:
  ```bash
  git checkout main
  git pull origin main
  ```
- Create a new branch:
  ```bash
  git checkout -b feature/your-feature
  ```
- Make your changes and test them:
  ```bash
  flutter test
  flutter run
  ```
- Commit changes with a clear message:
  ```bash
  git add .
  git commit -m "Add your descriptive commit message"
  ```
  Example: Add subscription screen UI with plan selection.
- Push your branch to GitHub:
  ```bash
  git push origin feature/your-feature
  ```
- Create a Pull Request (PR) on GitHub:
  - Target the `main` branch.
  - Provide a clear title and description of your changes.
  - Reference any related issues (e.g., Fixes #123).
  - Ensure tests pass and CI checks are green.
- Address feedback from reviewers. At least one approval is required for merging.
- Once approved, the PR will be merged by a maintainer, and the branch will be deleted.
- Don’t forget to update your local repository:
  ```bash
  git checkout main
  git pull origin main
  git branch -d feature/your-feature  # Delete unneeded branch
  ```

### Resolving Merge Conflicts
- If conflicts occur during a PR or merge:
  - Open the problematic files in an editor (e.g., VS Code).
  - Resolve conflicts by editing the marked sections.
  - Run:
    ```bash
    git add <file>
    git commit
    git push origin feature/your-feature
    ```

### Accidentally Pushed to the Wrong Branch
- If changes were pushed to `main` or another branch by mistake:
  - Create a new branch for the changes:
    ```bash
    git checkout -b feature/your-feature
    ```
  - Undo the changes in `main` (if they were pushed):
    ```bash
    git checkout main
    git reset --hard HEAD~1  # Revert the last commit (warning: data may be lost)
    git push origin main --force  # Force update main
    ```
  - Switch back to your branch and continue working:
    ```bash
    git checkout feature/your-feature
    git push origin feature/your-feature
    ```

### Forgot to Pull from `main`
- If your branch `feature/your-feature` is outdated, perform a `pull` from `main`:
  ```bash
  git checkout feature/your-feature # Switch to your branch
  git merge main # Merge changes from `main`
  ```
- If conflicts occur, follow the instructions in the "Resolving Merge Conflicts" section.

## Code Standards
- Follow the [Flutter style guide](https://dart.dev/effective-dart/style).
- Run `flutter format .` to format code.
- Run `flutter analyze` to catch issues.
- Write unit and widget tests for new features or bug fixes (see Testing).

## Testing
- Write tests for new features and bug fixes.
- Use `flutter test` to run unit and widget tests.
- Ensure test coverage remains high (aim for >80%).
- Example:
  ```dart
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      expect(find.text('Login'), findsOneWidget);
  });

## Database
### 1. Connecting to the Server
- Connect to the server via SSH. Replace `user` and `server-ip` with your username and server IP address:
  ```bash
  ssh user@server-ip
  ```

### 2. Viewing Directories
- Check available directories in the current directory:
  ```bash
  ls -d */
  ```
  This command displays all directories in the current path.

### 3. Navigating to the Project Directory
- Navigate to the project directory (replace `project-directory` with the actual directory name found in the previous step):
  ```bash
  cd project-directory
  ```

### 4. Viewing Files in the Directory
- View all files in the current directory to ensure `node_modules`, `package-lock.json`, and other files are present:
  ```bash
  ls
  ```

### 5. Removing Unnecessary Files
- Remove the `node_modules` directory and files `package-lock.json` and `index.js` to clean the project:
  ```bash
  rm -rf node_modules package-lock.json index.js
  ```

### 6. Verifying File Removal
- Ensure the files were removed by viewing all files (including hidden ones) in the directory:
  ```bash
  ls -la
  ```
  Verify that `node_modules`, `package-lock.json`, and `index.js` are no longer displayed.

### 7. Checking Running PM2 Processes
- View the list of all running PM2 processes to check the status of `vpn-server`:
  ```bash
  pm2 list
  ```

### 8. Stopping the VPN Server
- Stop the `vpn-server` process if it is running:
  ```bash
  pm2 stop vpn-server
  ```

### 9. Deleting the VPN Server Process
- Remove the `vpn-server` process from PM2 management:
  ```bash
  pm2 delete vpn-server
  ```

### 10. Adding New Files
- Add new server files via the Windows console:
  ```bash
  scp -r path-to-file\index.js user@server-ip:~/project-directory/
  ```

### 11. Updating Modules
- Update modules within the directory:
  ```bash
  npm install
  ```

### 12. Verifying Added Files
- View all files in the current directory to ensure `node_modules`, `index.js`, and other files are present:
  ```bash
  ls
  ```

### 13. Starting the VPN Server
- Start the Node.js application (`index.js`) and assign it the name `vpn-server` in PM2:
  ```bash
  pm2 start index.js --name vpn-server
  ```

### 14. Testing the Registration API
- Send a POST request to the registration endpoint to test the API and server:
  ```bash
  curl -X POST -H "Content-Type: application/json" -d '{"username":"testuser","password":"testpass123","email":"test@example.com"}' http://localhost:3000/register
  ```
  This command sends JSON data to the `/register` endpoint. Check the response to ensure the request was successful.

## Setting Up WireGuard on an Ubuntu Server

WireGuard is a modern and easy-to-configure VPN protocol. Below are the steps to install and configure WireGuard on your new Ubuntu server before the app release. These instructions account for your current architecture with server code and scripts for key generation.

### Prerequisites
- Access to the server via SSH with root or sudo privileges.
- Ubuntu installed (version 20.04 or 22.04 recommended).
- A static public IP address for the server.
- Ensure port 51820 (or another port of your choice) is open in the firewall and with your provider.
- The `/root/vpn-server/` directory is accessible and contains the `generate_vpn_key.sh` and `add_to_wg_conf.sh` scripts (as specified in your code).

## Setup Steps

### 1. Update the System
- Update packages on the server to avoid issues with outdated versions:
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

### 2. Install WireGuard
- Install WireGuard and required tools:
  ```bash
  sudo apt install wireguard wireguard-tools -y
  ```

### 3. Generate Server Private and Public Keys
- Generate a key pair for the server (these keys will be used in the configuration):
  ```bash
  wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
  ```
- The private key will be saved in `/etc/wireguard/privatekey`.
- The public key will be saved in `/etc/wireguard/publickey`.
- Update the `serverPublicKey` in the `/get-vpn-config` endpoint (in your code: `yrDYPAHAHQ3+2sdvCzQ+WHErdh0dNt+5fgJbukEMw6Fg0=`) with this public key.

### 4. Configure the Base WireGuard Configuration File
- Create or edit the configuration file `/etc/wireguard/wg0.conf`:
  ```bash
  sudo nano /etc/wireguard/wg0.conf
  ```
- Insert the following base configuration, replacing values with your own:
  ```
  [Interface]
  PrivateKey = <Your_Server_Private_Key>
  Address = 10.0.0.1/24
  ListenPort = 51820
  PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
  ```
- Replace `<Your_Server_Private_Key>` with the contents of `/etc/wireguard/privatekey`.
- Ensure the `eth0` interface matches your primary network interface (check with `ip a`).

### 5. Configure the Firewall
- Allow traffic through the WireGuard port and enable IP forwarding:
  ```bash
  sudo ufw allow 51820/udp
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  ```

### 6. Place the Scripts
- Ensure the scripts are located in the `/root/vpn-server/` directory:
  - `generate_vpn_key.sh` (generates a private key):
  - `add_to_wg_conf.sh` (adds a client to `wg0.conf`):
- Grant execution permissions:
  ```bash
  sudo chmod +x /root/vpn-server/generate_vpn_key.sh
  sudo chmod +x /root/vpn-server/add_to_wg_conf.sh
  ```

### 7. Start WireGuard
- Activate and start the WireGuard service:
  ```bash
  sudo wg-quick up wg0
  sudo systemctl enable wg-quick@wg0
  ```

### 8. Testing Integration with the Server
- Ensure the Node.js server (on port 3000) is running and uses the same script paths (`/root/vpn-server/`).
- Register a new user via the `/register` endpoint and verify via `/verify-email`. This will automatically generate a VPN key and add the client to `wg0.conf`.
- Check the WireGuard status:
  ```bash
  sudo wg show
  ```
- Verify that the new client (with an IP like `10.0.0.2`) is displayed.

### Notes
- Replace `<Your_Server_IP>` and keys with actual values.
- For multiple clients, the server automatically increments `AllowedIPs` (starting from `10.0.0.2/32`) thanks to `add_to_wg_conf.sh`.
- Regularly check WireGuard logs:
  ```bash
  journalctl -u wg-quick@wg0
  ```
- If script execution errors occur, ensure the `/root/vpn-server/` paths and permissions are correct.

### Testing
- After setup, test the VPN by connecting from your device and ensure the app can interact with the new server via API and WireGuard.
- Verify that keys are generated and added to `wg0.conf` correctly.

## Frequently Asked Questions (FAQ)

- ### What to do if WireGuard doesn’t connect?
  - Check if port 51820 is open in the firewall (`sudo ufw status`) and with your provider.
  - Ensure the keys match between the server and client.
- ### How to check if the server API is working?
  - Use the command from the "Testing the Registration API" section and check the response in the terminal.