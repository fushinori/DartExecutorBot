# DartExecutorBot
A telegram bot written in Dart using the [Teledart](https://github.com/DinoLeung/TeleDart) library.
- Executes dart code and returns results.
- Inline mode is also supported.

## Configuration
```bash
cp sample_config.dart config.dart
```
Edit config.dart accordingly.

## How to deploy
- ### Using Docker
  - Build docker image
  ```bash
  docker build -t dartexecutorbot .
  ```

  - Run it
  ```bash
  docker run -d --name dart dartexecutorbot
  ```

- ### Manual Installation
  - Installing dependencies
  ```bash
  pub get
  ```

  - Running the bot
  ```bash
  dart main.dart
  ```
