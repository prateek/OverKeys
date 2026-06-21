# Contributing to OverKeys

Thank you for your interest in contributing to OverKeys! We welcome contributions from the community to help improve this open-source keyboard layout visualizer. Whether you're fixing bugs, adding features, improving documentation, or suggesting ideas, your help is greatly appreciated.

## Ways to Contribute

There are many ways you can contribute to OverKeys:

- **Code Contributions**: Fix bugs, implement new features, or improve existing functionality
- **Documentation**: Improve docs, add tutorials, or update old instructions
- **Testing**: Report bugs or verify fixes and new features in nightly builds
- **Design**: Suggest UI/UX improvements
- **Community Support**: Help other users in discussions or issues

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Git](https://git-scm.com/downloads)

### Development Setup

1. **Fork the Repository**
   - Click the "Fork" button at the top of this repository
   - Clone your fork locally:

     ```bash
     git clone https://github.com/YOUR_USERNAME/OverKeys.git
     cd OverKeys
     ```

2. **Set Up the Development Environment**
   - Install dependencies:

     ```bash
     flutter pub get
     ```

   - Run the app for testing:

     ```bash
     flutter run -d windows
     flutter run -d macos
     ```

3. **Create a Feature Branch**
   - Create and switch to a new branch:

     ```bash
     git checkout -b feat/your-feature-name
     ```

   - Use descriptive branch names (e.g., `feat/add-dark-theme`, `fix/keyboard-layout-bug`, `docs/update-installation-guide`)

### Building from Source

For detailed build instructions:

```bash
# For testing
flutter run -d windows
flutter run -d macos

# For release builds
flutter build windows
flutter build macos
```

The Windows release executable will be located at
`build\windows\x64\runner\Release`. The macOS app bundle will be located under
`build/macos/Build/Products/Release`.

## Coding Standards

To maintain code quality and consistency:

- Follow Dart's [effective Dart guidelines](https://dart.dev/guides/language/effective-dart)
- Use meaningful variable and function names
- Add comments for complex logic
- Write clear commit messages following [conventional commits](https://www.conventionalcommits.org/)
- Ensure your code passes `flutter analyze`

### Commit Message Format

Use the following format for commit messages:

```text
type(scope): description

[optional body]

[optional footer]
```

Types:

- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:

- `feat: add support for custom keyboard themes`
- `fix: resolve crash when loading invalid layout file`
- `docs: update installation guide for Windows 11`

## Testing

- Run tests before submitting changes:

  ```bash
  flutter test
  ```

- Add tests for new features when possible
- Ensure all existing tests pass

## Submitting Changes

1. **Commit Your Changes**

   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

2. **Push to Your Fork**

   ```bash
   git push origin feat/your-feature-name
   ```

3. **Create a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your branch and provide a clear description
   - Reference any related issues

### Pull Request Guidelines

- Provide a clear title and description
- Reference related issues (e.g., "Fixes #123")
- Include screenshots for UI changes
- Ensure CI checks pass
- Request review from maintainers

## Reporting Issues

Found a bug or have a feature request? Please:

1. Check existing [issues](https://github.com/conventoangelo/OverKeys/issues) first
2. Use the appropriate issue template (bug report or feature request)
3. Provide detailed information:
   - Steps to reproduce
   - Expected vs. actual behavior
   - System information (OS, Flutter version, etc.)
   - Screenshots if applicable

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please read our [Code of Conduct](./CODE_OF_CONDUCT.md) to understand our expectations for behavior and how to report issues.

## Recognition

We appreciate all contributions! Check out our top contributors:

<a href="https://github.com/conventoangelo/OverKeys/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=conventoangelo/OverKeys" alt="contrib.rocks image" />
</a>

## Questions?

If you have questions about contributing, feel free to:

- Open a [discussion](https://github.com/conventoangelo/OverKeys/discussions)
- Contact the maintainer directly via [email](mailto:convento.angelo@gmail.com)

Thank you for contributing to OverKeys! 🚀
