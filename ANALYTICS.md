# События аналитики

<!-- Файл собран автоматически: `swift Tools/AnalyticsRegistry.swift`.
     Руками не правят — источник правды в коде. -->

Имя события целиком — это префикс модуля плюс имя из `track(...)`.
Как завести новое, описано в скилле `analytics-event`.

## app · `App/Sources/AppAnalytics.swift`

| Событие | Параметры | Что значит |
| --- | --- | --- |
| `app_deeplink_opened` | `source`, `target` | Ссылка привела на экран. |
| `app_deeplink_unknown` | `target` | Ссылка есть, а маршрута под неё нет: обычно это ярлык, оставшийся от прошлой версии, — такое видно только по аналитике. |

## compress · `Modules/Features/CompressFeature/Sources/CompressAnalytics.swift`

| Событие | Параметры | Что значит |
| --- | --- | --- |
| `compress_level_picked` | `delta_percent`, `preset` | Степень выбрана, сжатие запущено. |

## flow · `Modules/Core/SlimlyMediaFlow/Sources/Analytics/FlowAnalytics.swift`

| Событие | Параметры | Что значит |
| --- | --- | --- |
| `flow_access_answered` | `status`, `tool` | Система ответила на запрос доступа к медиатеке — первая развилка любого инструмента: отказ обрывает флоу на самом входе, и без этого события такой уход выглядел бы как обычный отвал с экрана выбора. |
| `flow_files_picked` | `count`, `input_mb`, `tool` | Файлы выбраны, инструмент пошёл к настройкам. |
| `flow_originals_deleted` | `count`, `tool` | Оригиналы удалены после сохранения: место освобождено по-настоящему, а не «сжато и оставлено рядом». |
| `flow_result_previewed` | `tool` | Открыли просмотр готового файла — результату не поверили на слово. |
| `flow_result_saved` | `count`, `destination`, `output_mb`, `tool` | Готовые файлы сохранены — ради этого затевался весь флоу. |
| `flow_run_cancelled` | `percent`, `tool` | С экрана обработки ушли, не дождавшись конца: уход рвёт поток, и готовых файлов после него не остаётся. |
| `flow_run_finished` | `count`, `duration_ms`, `failed`, `input_mb`, `output_mb`, `tool` | Обработка дошла до конца. |
| `flow_run_started` | `count`, `format`, `input_mb`, `tool` | Обработка началась — настройки приняты, дальше работает устройство. |
| `flow_save_failed` | `count`, `tool` | Часть файлов сохранить не удалось. |

## home · `Modules/Features/HomeFeature/Sources/HomeAnalytics.swift`

| Событие | Параметры | Что значит |
| --- | --- | --- |
| `home_profile_opened` | — | Открыт профиль — экран статистики и настроек. |
| `home_tool_opened` | `tool` | Инструмент открыт с главной. |

## onboarding · `Modules/Features/OnboardingFeature/Sources/OnboardingAnalytics.swift`

| Событие | Параметры | Что значит |
| --- | --- | --- |
| `onboarding_finished` | `page`, `skipped` | Тур закончен. |
| `onboarding_page_opened` | `page` | Открыта следующая страница тура. |

## profile · `Modules/Features/ProfileFeature/Sources/ProfileAnalytics.swift`

| Событие | Параметры | Что значит |
| --- | --- | --- |
| `profile_language_changed` | `language` | Язык интерфейса выбран вручную или возвращён к телефонному. |
| `profile_statistics_opened` | `source` | Открыт разбор по инструментам. |
| `profile_statistics_range_changed` | `range` | Сменили срез времени. |

## scan · `Modules/Features/ScanFeature/Sources/ScanAnalytics.swift`

| Событие | Параметры | Что значит |
| --- | --- | --- |
| `scan_bounds_confirmed` | `count`, `edited`, `missed` | Границы страниц приняты. |
| `scan_camera_cancelled` | `count` | Из камеры вышли, снятое выброшено. |
| `scan_pages_captured` | `count`, `mode` | Съёмка закончена, страницы уходят дальше. |
| `scan_source_picked` | `source` | Откуда берут страницы. |

