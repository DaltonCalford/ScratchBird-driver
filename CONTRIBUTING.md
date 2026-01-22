# Contributing to ScratchBird Drivers

Thank you for your interest in contributing to ScratchBird Drivers!

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Set up the development environment for the driver(s) you want to work on
4. Create a feature branch from `main`

## Development Guidelines

### General Requirements

- **Tests Required** - All new features and bug fixes must include tests
- **Documentation** - Update relevant documentation for any changes
- **Code Style** - Follow the existing code style for each language
- **Commit Messages** - Use clear, descriptive commit messages

### Language-Specific Guidelines

#### Go
- Follow [Effective Go](https://golang.org/doc/effective_go) guidelines
- Run `go fmt` before committing
- Run `go vet` and fix any issues
- Tests: `go test ./...`

#### Python
- Follow PEP 8 style guide
- Use type hints where appropriate
- Run `black` and `isort` for formatting
- Tests: `pytest`

#### Node.js/TypeScript
- Follow the existing ESLint configuration
- Use TypeScript for new code
- Run `npm run lint` before committing
- Tests: `npm test`

#### Rust
- Follow standard Rust conventions
- Run `cargo fmt` before committing
- Run `cargo clippy` and address warnings
- Tests: `cargo test`

#### .NET
- Follow Microsoft C# coding conventions
- Use `dotnet format` for formatting
- Tests: `dotnet test`

#### Java/JDBC
- Follow Google Java Style Guide
- Tests: `./gradlew test`

#### PHP
- Follow PSR-12 coding standard
- Tests: `composer test`

#### Ruby
- Follow Ruby Style Guide
- Run `rubocop` for linting
- Tests: `rake test`

#### R
- Follow tidyverse style guide
- Tests: `testthat`

#### Pascal
- Follow standard Pascal conventions
- Document public interfaces

## Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code
   - Add tests
   - Update documentation

3. **Test your changes**
   - Run the test suite for affected drivers
   - Ensure all tests pass

4. **Commit your changes**
   ```bash
   git commit -m "Add feature: description of your changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Ensure CI checks pass

## Reporting Issues

When reporting issues, please include:

- Driver language and version
- ScratchBird server version
- Operating system
- Steps to reproduce
- Expected vs actual behavior
- Error messages or logs

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

## Questions?

- Open a GitHub issue for questions
- Check existing issues before creating new ones
- See the main [ScratchBird](https://github.com/DaltonCalford/ScratchBird) project for server-related questions

## License

By contributing, you agree that your contributions will be licensed under the project's IDPL license.
