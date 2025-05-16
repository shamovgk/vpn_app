# Contributing to VPN App

Thank you for considering contributing to the VPN App! This document outlines the process for contributing to the project to ensure a smooth and consistent workflow.

## Getting Started
1. Fork the repository on GitHub.
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/vpn_app.git
   cd vpn_app
3. Install dependencies:
   ```bash
   flutter pub get
4. Ensure your environment meets the requirements (see README.md).

## Reporting Issues
 - Use the GitHub Issues tracker to report bugs or suggest features.
 - Provide a clear title and description.
 - Include steps to reproduce (for bugs) or a detailed proposal (for features).
 - Check for existing issues to avoid duplicates.

## Branching Strategy
 - The default branch is main.
 - Create a new branch for each contribution:
     - feature/<feature-name> for new features (e.g., feature/subscription-screen).
     - bugfix/<bug-description> for bug fixes (e.g., bugfix/login-error).
     - docs/<doc-update> for documentation updates (e.g., docs/update-readme).
     - hotfix/<issue-description> for urgent fixes (e.g., hotfix/vpn-connection).
 - Use descriptive, hyphen-separated names (e.g., feature/add-vpn-protocol).

## Workflow
1. Start from the latest main branch:
    ```bash
    git checkout main
    git pull origin main
2. Create a new branch:
    ```bash
    git checkout -b feature/your-feature
3. Make your changes and test them:
    ```bash
    flutter test
    flutter run
4. Commit changes with a clear message:
    ```bash
    git add .
    git commit -m "Add your descriptive commit message"  

Example: Add subscription screen UI with plan selection. 

5. Push your branch to GitHub:
   ```bash
   git push origin feature/your-feature  
6. Create a Pull Request (PR) on GitHub:
 - Target the main branch.
 - Provide a clear title and description of your changes.
 - Reference any related issues (e.g., Fixes #123).
 - Ensure tests pass and CI checks are green. 
7. Address feedback from reviewers. At least one approval is required for merging.
8. Once approved, the PR will be merged by a maintainer, and the branch will be deleted.
9. Don't forget to update your local repository:
    ```bash
    git checkout main
    git pull origin main
    git branch -d feature/subscription-screen  # Delete unneeded branch

### Resolving Merge Conflicts
If conflicts occur during a PR or merge:
1. Open the problematic files in an editor (e.g., VS Code).
2. Resolve conflicts by editing the marked sections.
3. Run:
    ```bash
    git add <file>
    git commit
    git push origin feature/your-feature
### Accidentally Pushed to the Wrong Branch
If changes were pushed to main or another branch by mistake:

1. Create a new branch for the changes:
    ```bash
    git checkout -b feature/your-feature
2. Undo the changes in main (if they were pushed):
    ```bash
    git checkout main
    git reset --hard HEAD~1  # Revert the last commit (warning: data may be lost)
    git push origin main --force  # Force update main
3. Switch back to your branch and continue working:
    ```bash
    git checkout feature/your-feature
    git push origin feature/your-feature
### Forgot to Pull main
If your branch feature/subscription-screen is outdated, pull changes from main:
    ```bash
    git checkout feature/subscription-screen # Switch to your branch
    git merge main # Merge changes from main

If conflicts occur, follow the instructions in the "Resolving Merge Conflicts" section.

## Code Standards
 - Follow the [Flutter style guide](https://dart.dev/effective-dart/style).
 - Run flutter format . to format code.
 - Run flutter analyze to catch issues.
 - Write unit and widget tests for new features or bug fixes (see Testing).

## Testing
 - Write tests for new features and bug fixes.
 - Use flutter test to run unit and widget tests.
 - Ensure test coverage remains high (aim for >80%).
 - Example:
    ```dart
    testWidgets('Login screen renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        expect(find.text('Login'), findsOneWidget);
    });
