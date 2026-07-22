# Flutter Comics Viewer

Flutter плагин для отображения интерактивных комиксов и пазлов с анимациями и звуком.

## Возможности

- **Рендеринг комиксов**: Отображение анимированных комиксов с автоматической прокруткой и синхронизацией звука
- **Поддержка пазлов**: Рендеринг интерактивных сеток пазлов с навигацией по кусочкам
- **Воспроизведение звука**: Аудио синхронизированное с позицией прокрутки
- **Кросс-платформенность**: Работает на Android и iOS
- **Простой API**: Всего 5 основных методов для управления воспроизведением комиксов

## Установка

Добавьте в `pubspec.yaml`:

```yaml
dependencies:
  flutter_comics_viewer:
    path: ../путь/к/flutter_comics_viewer
```

Затем выполните:

```bash
flutter pub get
```

## Быстрый старт

```dart
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';

class ComicsScreen extends StatefulWidget {
  @override
  _ComicsScreenState createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen> {
  final ComicsViewerController _controller = ComicsViewerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ComicsViewer(
        controller: _controller,
        filePath: '/путь/к/episode.comics',
        onLoaded: () {
          print('Комикс загружен!');
          _controller.play();
        },
        onScrollChanged: (position) {
          print('Позиция прокрутки: $position');
        },
        onError: (error) {
          print('Ошибка: $error');
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Comics API

### ComicsViewer Widget

Главный виджет для отображения комиксов.

```dart
ComicsViewer({
  required ComicsViewerController controller,
  required String filePath,           // Путь к .comics файлу
  VoidCallback? onLoaded,             // Вызывается когда комикс загружен
  ValueChanged<double>? onScrollChanged, // Позиция прокрутки изменилась
  ValueChanged<String>? onError,      // Произошла ошибка
  int languageIndex = 0,              // Выбор языка (начиная с 0)
  bool soundEnabled = true,           // Включить/выключить звуки
  bool showPreview = false,           // Показать/скрыть превью слои
})
```

### ComicsViewerController

Контроллер для управления воспроизведением комиксов.

#### Методы

**1. Загрузка и отображение**

```dart
// Загрузить .comics файл (вызывается автоматически виджетом)
await controller.loadComics('/путь/к/файлу.comics');
```

**2. Управление воспроизведением**

```dart
// Запустить авто-прокрутку
controller.play();

// Поставить на паузу
controller.pause();
```

**3. Навигация**

```dart
// Установить позицию прокрутки (от 0.0 до duration)
controller.setScrollPosition(500.0);

// Получить текущую позицию прокрутки
double position = controller.getScrollPosition();
```

**4. Превью и звук**

```dart
// Переключить видимость превью слоёв
controller.togglePreview(true);  // Показать превью
controller.togglePreview(false); // Скрыть превью

// Переключить воспроизведение звука
controller.toggleSounds(true);   // Включить звуки
controller.toggleSounds(false);  // Выключить звуки
```

**5. Очистка ресурсов**

```dart
// Освободить ресурсы (вызывать в dispose)
controller.dispose();
```

#### Свойства (только чтение)

```dart
// Проверить играет ли сейчас
bool playing = controller.isPlaying;

// Получить общую высоту прокрутки
double totalHeight = controller.duration;

// Получить текущую позицию
double currentPos = controller.currentPosition;
```

## Puzzle API

### PuzzleViewer Widget

Виджет для отображения интерактивных пазлов.

```dart
PuzzleViewer({
  required PuzzleViewerController controller,
  required String filePath,           // Путь к .puzzle файлу
  VoidCallback? onLoaded,
  ValueChanged<int>? onPieceSelected, // Выбран кусочек по индексу
  ValueChanged<String>? onError,
  bool soundEnabled = true,
  bool showPreview = false,
})
```

### PuzzleViewerController

Контроллер для взаимодействия с пазлом.

```dart
// Загрузить puzzle файл
await controller.loadPuzzle('/путь/к/puzzle.puzzle');

// Перейти к кусочку по индексу
controller.selectPiece(5);

// Получить текущий кусочек
int currentPiece = controller.currentPieceIndex;

// Получить общее количество кусочков
int totalPieces = controller.totalPieces;

// Управление воспроизведением текущего кусочка
controller.play();
controller.pause();

// Переключить превью/звуки для всех кусочков
controller.togglePreview(true);
controller.toggleSounds(false);

// Очистка
controller.dispose();
```

## Формат файлов

### .comics Файл

Файл .comics - это ZIP архив, содержащий:

- `data.json` - Структура и метаданные комикса
- `layers/` - Изображения слоёв (PNG)
- `sounds/` - Аудио файлы (MP3)

**Пример использования:**

```dart
// Из bundle приложения
final filePath = 'assets/episodes/episode1.comics';

// Из скачанного файла
final filePath = '/data/user/0/com.app/files/episode1.comics';
```

### .puzzle Файл

Файл .puzzle - это ZIP архив, содержащий:

- Метаданные пазла (сетка расположения)
- Множество .comics файлов (по одному на кусочек)

## Полный пример

```dart
import 'package:flutter/material.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';

class ComicsPlayerScreen extends StatefulWidget {
  final String comicsPath;

  ComicsPlayerScreen({required this.comicsPath});

  @override
  _ComicsPlayerScreenState createState() => _ComicsPlayerScreenState();
}

class _ComicsPlayerScreenState extends State<ComicsPlayerScreen> {
  late ComicsViewerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = ComicsViewerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Просмотр комиксов'),
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
                _isPlaying ? _controller.play() : _controller.pause();
              });
            },
          ),
        ],
      ),
      body: ComicsViewer(
        controller: _controller,
        filePath: widget.comicsPath,
        soundEnabled: true,
        onLoaded: () {
          setState(() {
            _controller.play();
            _isPlaying = true;
          });
        },
        onScrollChanged: (position) {
          // Обновить прогресс-бар
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $error')),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Требования

- **Flutter**: 3.3.0+
- **Dart**: 3.0.0+
- **Android**: API 21+ (Android 5.0)
- **iOS**: 13.0+

## Bundle ID

```
net.nativemind.flutter.comics.viewer
```

## Лицензия

Copyright © 2017-2026 Iron Water Studio, NativeMind. Все права защищены.
