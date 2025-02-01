# Contributing to KeyPane

Thank you for your interest in contributing to KeyPane! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to maintain a welcoming, inclusive, and harassment-free environment. Be kind and respectful to others.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in the [Issues](https://github.com/danielwetzel/KeyPane/issues)
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Your system information (macOS version, hardware)

### Suggesting Enhancements

1. Check existing [Issues](https://github.com/danielwetzel/KeyPane/issues) for similar suggestions
2. Create a new issue with:
   - Clear description of the enhancement
   - Explanation of why it would be useful
   - Any relevant mockups or examples

### Adding Keyboard Layouts

KeyPane welcomes contributions for additional keyboard layouts:

1. Create a new JSON file in `Resources/` following the format in `qwertzDE.json`
2. Include:
   - All standard keys
   - Option and Option+Shift characters
   - Shift characters
   - Proper key positioning
3. Add appropriate tests
4. Update documentation

### Pull Requests

1. Fork the repository
2. Create a new branch for your feature
3. Make your changes
4. Write or update tests
5. Update documentation
6. Submit a pull request with:
   - Clear description of changes
   - Reference to related issue(s)
   - Screenshots for UI changes

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/danielwetzel/KeyPane.git
cd KeyPane
```

2. Create a new Xcode project:
   - Open Xcode
   - Create a new project (File > New > Project)
   - Choose "App" under macOS
   - Set the following options:
     - Product Name: KeyPane
     - Team: Your development team
     - Organization Identifier: de.d-wetzel
     - Interface: SwiftUI
     - Language: Swift
     - Minimum Deployment: macOS 13.5
     - Create Git repository: No
     - Include Tests: Yes

3. Configure the project:
   - Add the following capabilities in the target's "Signing & Capabilities":
     - App Sandbox
     - Input Monitoring
     - Automation Control
   - Set the following in Info.plist:
     - Privacy - Input Monitoring Usage Description
     - Privacy - Automation Control Usage Description

4. Copy source files:
   - Delete the default ContentView.swift
   - Copy all .swift files from the repository into your project
   - Create a Resources folder and copy:
     - keyCodeMappings.json
     - qwertzDE.json

5. Install development dependencies:
   - Xcode 14.0 or later
   - macOS 13.5 or later

6. Build and run:
   - Select "My Mac" as the target
   - Press Cmd+R to build and run

## Code Style

- Follow Swift style guidelines
- Use SwiftUI for new views
- Maintain existing code structure
- Add comments for complex logic
- Use meaningful variable/function names

## Testing

- Add unit tests for new features
- Ensure existing tests pass
- Test on multiple macOS versions
- Test with different keyboard layouts

## Documentation

- Update README.md for new features
- Add inline documentation
- Update keyboard layout documentation
- Include screenshots for UI changes

## Release Process

1. Update version numbers
2. Update changelog
3. Create release notes
4. Submit for review

## Questions?

Feel free to:
- Open an issue for questions
- Join discussions
- Contact maintainers

## License

By contributing, you agree that your contributions will be licensed under the MIT License.