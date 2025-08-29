# Contributing to +A_DevAfrica

We welcome contributions to the +A_DevAfrica platform! To ensure a smooth and collaborative development process, please follow these guidelines.

## Table of Contents

1.  [Getting Started](#getting-started)
2.  [Branching Model](#branching-model)
3.  [Commit Messages](#commit-messages)
4.  [Pull Request Checklist](#pull-request-checklist)
5.  [Code Style](#code-style)
6.  [Running Tests](#running-tests)
7.  [Reporting Bugs](#reporting-bugs)
8.  [Suggesting Enhancements](#suggesting-enhancements)

## 1. Getting Started

Before you begin, make sure you have the development environment set up as described in the main `README.md`.

## 2. Branching Model

We use a feature-branch workflow:

*   **`main`**: This branch contains the latest stable, deployed version of the application.
*   **`develop`**: This branch is where all new features and bug fixes are integrated before being merged into `main`.
*   **Feature Branches**: For any new feature or bug fix, create a new branch off `develop`. Name your branch descriptively, e.g., `feature/add-user-profile` or `bugfix/fix-login-issue`.

    ```bash
    git checkout develop
    git pull origin develop
    git checkout -b feature/your-feature-name
    ```

## 3. Commit Messages

We follow the Conventional Commits specification for our commit messages. This helps in generating changelogs and understanding the history of changes.

Examples:

*   `feat: Add user authentication`
*   `fix: Correct login redirect bug`
*   `docs: Update README with deployment instructions`
*   `refactor: Improve performance of project listing`
*   `test: Add unit tests for payment service`

## 4. Pull Request Checklist

Before submitting a pull request (PR), please ensure the following:

*   You have branched off `develop`.
*   Your code adheres to the [Code Style](#5-code-style) guidelines.
*   All tests pass locally ([Running Tests](#6-running-tests)).
*   You have added new tests for your changes, if applicable.
*   Your commit messages follow the [Conventional Commits](#3-commit-messages) specification.
*   You have updated documentation (e.g., `README.md`, `API_SPEC.md`) if your changes require it.
*   Your PR has a clear title and description explaining the changes.
*   You have requested a code review from at least one team member.

## 5. Code Style

We use RuboCop for Ruby code style enforcement. Please ensure your code passes RuboCop checks before submitting a PR.

```bash
bundle exec rubocop
```

For frontend (JavaScript/CSS), ensure consistency with existing patterns. We use Tailwind CSS for styling.

## 6. Running Tests

Always run the test suite before submitting a PR to ensure your changes haven't introduced any regressions.

```bash
bundle exec rspec
```

For JavaScript tests (if any):

```bash
yarn test
```

## 7. Reporting Bugs

If you find a bug, please open an issue on our GitHub repository. Use the `bug_report.md` template provided in `.github/ISSUE_TEMPLATE/`.

## 8. Suggesting Enhancements

For feature requests or enhancements, please open an issue using the `feature_request.md` template in `.github/ISSUE_TEMPLATE/`.

Thank you for contributing!

