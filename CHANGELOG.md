# Telewhite iOS — Журнал изменений

Лог кастомных изменений форка (модуль **Telewhite Mods** и связанные хуки).
Записи сверху вниз: новые сверху. Формат: `дата — коммит — что сделано`.

Легенда: **[Добавлено]** новая функция · **[Исправлено]** багфикс · **[Улучшено]** доработка · **[Рефакторинг]** без изменения поведения · **[Инфра]** сборка/CI.

---

## 2026-07-09

- **[Добавлено]** Переводчик исходящих сообщений (пер-чат). В навбаре личных чатов появилась кнопка-переводчик
  (рисованная иконка «文 → A», точка = включено): тап включает/выключает перевод исходящих для этого чата,
  долгий тап (0.35s) открывает ActionSheet выбора языка (11 языков, по умолчанию English, язык запоминается пер-чат).
  При включённом переводе текст молча переводится в `sendCurrentMessage` через `context.engine.messages.translate`
  (entities сохраняются, таймаут 10s; при ошибке отправляется оригинал с тостом «Translation failed»).
  Медиа-подписи, редактирование и секретные чаты не затрагиваются. Хранение: `outgoingTranslateButtonEnabled`
  (тумблер видимости в Telewhite Mods → Messenger), `outgoingTranslationPeerIds`, `outgoingTranslationLanguages`
  в `TelewhiteModsSettings` (UserDefaults). Реализация: новый кейс `toggleOutgoingTranslation` в `ChatNavigationButton`,
  `quaternaryRightNavigationButtonForChatInterfaceState` + кастомная нода `TelewhiteOutgoingTranslationButtonNode`
  (UIBarButtonItem(customDisplayNode:) с long-press распознавателем). Файлы: `TelewhiteModsController.swift`,
  `ChatNavigationButton.swift`, `ChatInterfaceStateNavigationButtons.swift`, `UpdateChatPresentationInterfaceState.swift`,
  `ChatControllerNavigationButtonAction.swift`, `ChatController.swift`, `ChatControllerNode.swift`.
- **[Добавлено]** Тонировка удалённых сообщений. Сообщения с `TelewhiteDeletedMessageAttribute` теперь помечаются
  визуально: поверх фона бабла (под контентом) добавляется overlay-нода `telewhiteDeletedOverlayNode` —
  второй `ChatMessageBackground` с `customHighlightColor = black` (alpha 0.35), повторяющий
  форму бабла вместе с хвостиком (по паттерну `backgroundHighlightNode`). Работает в паре с уже существующим
  затемнением `mainContainerNode.alpha = 0.55`. Overlay создаётся/удаляется в apply рядом с `setType`
  и синхронизирует frame во всех трёх ветках обновления layout (анимированная, extracted, статичная).
  Файл: `submodules/TelegramUI/Components/Chat/ChatMessageBubbleItemNode/Sources/ChatMessageBubbleItemNode.swift`.

## 2026-07-03

- **[Добавлено]** Диагностика push-уведомлений. В `Telewhite Mods → Developer` добавлены строки
  «Push status» и «APNs token»: приложение сохраняет результат регистрации в APNs
  (`didRegisterForRemoteNotificationsWithDeviceToken` / `didFailToRegister...`) в `UserDefaults`
  и показывает его прямо в настройках. Токен можно скопировать по тапу. Это позволяет на сайдлоад-сборке
  без Xcode понять, выдал ли Apple токен для текущего профиля подписи — если статус не «Registered»,
  пуши работать не будут (причина в подписи/профиле, а не в коде). Файлы: `AppDelegate.swift`,
  `TelewhiteModsController.swift`.
- **[Добавлено]** AMOLED-режим теперь реально работает. Раньше тумблер `amoledMode` сохранялся, но нигде не читался.
  Добавлен `submodules/TelegramPresentationData/Sources/TelewhiteAmoledTheme.swift`, который превращает
  тёмную тему в true-black: фон чатов, списка чатов, панелей и меню становится чистым чёрным (`0x000000`),
  карточки/ячейки — приглушённо-чёрными (`0x1c1c1e`). К светлым темам не применяется.
  Хук встроен в обе точки сборки темы в `PresentationData.swift`; тема пересобирается на лету при
  переключении тумблера (через сигнал на уведомление `TelewhiteModsSettingsDidChange`).
- **[Рефакторинг]** `2808f38` — Telewhite Mods: все одиночные тумблеры настроек переведены на общий хелпер `switchItem(...)`.
  Убрано ~150 строк копипасты в `submodules/SettingsUI/Sources/TelewhiteModsController.swift`.
  Поведение сохранено полностью, включая особые случаи:
  - `showProfileIds` — по-прежнему ставит `showUserIds` и `showChatIds` вместе;
  - `ghostMessages` → пишет в `hideReadReceipts`;
  - `channelContentRestrictionBypass` → пишет в `contentRestrictionBypass`;
  - ветки перевода (`autoTranslateEnglish`) и текстовый инпут VPN оставлены inline.
- **[Инфра]** `ec5eba7` — В генерируемых профилях принудительно выставляется production `aps-environment`,
  чтобы пересобранные sideload-сборки получали push-уведомления.
- **[Улучшено]** `d9c553d` — Мгновенный релайаут списка чатов при переключении компактного режима.
- **[Улучшено]** `f72a706` — При включённом `hidePhoneInSettings` вместо номера телефона показывается «—».
- **[Улучшено]** `2a5d5a6` — Для строки настроек Mods используется стандартная иконка оформления Telegram.
- **[Изменено]** `f0e137f` — Ghost mode стал **только per-chat** (убран глобальный ghost, двусторонний presence).
- **[Исправлено]** `9936229` — Исправлена ориентация иконки ghost mode (перевёрнута вертикально).
- **[Исправлено]** `8c9a36c` — Исправлена ориентация иконки VPN (перевёрнута вертикально).

## 2026-07-02

- **[Улучшено]** `9d33549` — Улучшены визуал Mods и хуки приватности.
- **[Улучшено]** `32d4387` — Улучшены UI Mods и элементы управления приватностью.
- **[Улучшено]** `77a4c6c` — Улучшены приватность и UI Mods.

## 2026-07-01

- **[Улучшено]** `3933eab` — Улучшены элементы управления ghost и переводом.
- **[Изменено]** `8c587e7` — Для ghost mode используется иконка приватности Telegram.
- **[Исправлено]** `070d6bc` — Исправлена сборка настроек Mods.
- **[Исправлено]** `8e3af96` — Исправлена отрисовка иконки VPN.
- **[Улучшено]** `302507b` — Улучшены элементы управления Mods.
- **[Исправлено]** `6c73479` — Исправлена проверка типа собеседника для кнопки ghost.
- **[Исправлено]** `840d9430` — Исправлены хуки приватных модов.
- **[Добавлено]** `cbba177` — Подключены (wired) приватные моды Telewhite.
- **[Добавлено]** `78ca860` — Добавлена быстрая кнопка ghost mode прямо в чате.
- **[Добавлено]** `a9e7b8e` — Добавлен экран настроек Telewhite Mods.

## 2026-06-30

- **[Инфра]** `1698252` — Настроен CI для форка Telewhite iOS.

---

## Как обновлять этот файл

При каждом новом изменении добавляйте запись **в начало** соответствующей даты в формате:

```
- **[Тег]** `короткий-хеш` — краткое описание что и зачем.
```

Теги: `[Добавлено]`, `[Исправлено]`, `[Улучшено]`, `[Изменено]`, `[Рефакторинг]`, `[Инфра]`.
