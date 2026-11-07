# VerifSDK для iOS

SDK проводит пользователя через проверку документов, заполнение данных и селфи.
Вы подключаете пакет, получаете сессию от своего сервера и открываете экран SDK.
Набор шагов определяется процессом проверки, настроенным на сервере.

Руководство для **SDK 0.2.0**: один `VerifSDK.xcframework` и отдельный ресурсный
bundle. При подключении через SwiftPM ресурсы доставляются автоматически.
Если вы обновляетесь с 0.1.x, прочитайте раздел «Обновление с 0.1.x» ниже.

## Что понадобится

- Приложение на **iOS 16.0** или новее, на SwiftUI или UIKit.
- Минимальная поддерживаемая версия Xcode: **27.3**.
- Ваш сервер, который может получить сессию проверки в Verif.
- Интернет и разрешение камеры. Для настоящей съёмки нужен физический iPhone.

Для подключения готового пакета **не нужны Tuist, Docker и сборка SDK из исходников**.

## 1. Подключите пакет

1. В Xcode откройте **File → Add Package Dependencies…**.
2. Вставьте адрес `https://github.com/verif-online/msdk-ios`.
3. Выберите версию: **Exact Version → 0.2.0**.
4. Добавьте продукт **VerifSDK** в target приложения.
5. В файле запуска проверки добавьте `import VerifSDK`.

SwiftPM сам подключит фреймворки и ресурсы. Отдельно импортировать дизайн-систему
или копировать `VerifSDKResources.bundle` при таком подключении не нужно.
Для переданного вам локального пакета выберите **Add Local…** и каталог с его
`Package.swift`, затем тот же продукт `VerifSDK`.

## 2. Разрешите доступ к камере

В **Info.plist приложения** добавьте `Privacy - Camera Usage Description`
(`NSCameraUsageDescription`):

```xml
<key>NSCameraUsageDescription</key>
<string>Камера нужна, чтобы сфотографировать документ и сделать селфи для проверки личности.</string>
```

Сам запрос разрешения покажет SDK. Без этого ключа iOS не позволит нормально
открыть камеру. Если пользователь запретил доступ, изменить решение он сможет
в настройках приложения на iPhone. Перевод системного запроса задаёт ваше
приложение, а не настройки строк SDK.

## 3. Получите сессию от своего сервера

1. Приложение просит **ваш сервер** начать проверку пользователя.
2. Ваш сервер вызывает `POST /sdk/init` в Verif и обрабатывает ошибки этого запроса.
3. Ваш сервер возвращает приложению `token` и `expiresAt`.
4. Приложение передаёт эти значения в SDK.

API-ключи, секреты и расчёт подписи остаются на сервере. В приложение их добавлять
не нужно. В этом способе запуска SDK сам не вызывает `/sdk/init`.

Преобразуйте `expiresAt` из ответа своего сервера в Swift `Date`. Это момент
окончания действия токена, **не количество секунд**. Формат даты определяет ваш сервер.

```swift
import Foundation
import VerifSDK

func makeConfiguration(
    token: String,
    expiresAt: Date
) throws -> VerifSessionConfiguration {
    let session = try SdkSessionCredentials(token: token, expiresAt: expiresAt)
    return VerifSessionConfiguration(
        session: session,
        baseURL: URL(string: "https://api.dev.verif-online.ru")!,
        locale: Locale(identifier: "ru")
    )
}
```

Передайте в эту функцию токен и дату из ответа вашего сервера, не тестовые
константы. Токен допустим без префикса или с одним `Bearer `.
Не сохраняйте его в логах и репозитории.

| Окружение | `baseURL` |
| --- | --- |
| Разработка и тестирование | `https://api.dev.verif-online.ru` |
| Рабочее приложение | `https://api.verif-online.ru` |

Не добавляйте `/sdk` к адресу. Токен и адрес должны относиться к одному окружению.
Без явного `baseURL` SDK использует **production**, поэтому в тестах задавайте dev-адрес.

## 4. Откройте проверку

Выберите пример для вашего интерфейса. `configuration` — конфигурация из предыдущего
шага. Перед новой попыткой получите новую сессию и подготовьте новую конфигурацию:
токен проверки не является постоянным ключом приложения.

### SwiftUI

Пример кнопки для уже полученной сессии. `onResult` и `onFailure` — обработчики
вашего приложения. Экран создаётся при нажатии, а не при каждом пересчёте `body`.

```swift
import SwiftUI
import VerifSDK

@MainActor
struct VerificationButton: View {
    let configuration: VerifSessionConfiguration
    let onResult: (VerifResult) -> Void
    let onFailure: (Error) -> Void

    @State private var flow: VerifFlowView?
    @State private var isPresented = false

    var body: some View {
        Button("Начать проверку") {
            flow = Verif.start(
                configuration: configuration,
                onFlowFinished: { result in
                    isPresented = false
                    onResult(result)
                },
                onError: { error in
                    isPresented = false
                    onFailure(error)
                }
            )
            isPresented = true
        }
        .disabled(isPresented)
        .fullScreenCover(
            isPresented: $isPresented,
            onDismiss: { flow = nil }
        ) {
            if let flow {
                flow
            }
        }
    }
}
```

### UIKit

Передайте **уже показанный** `UINavigationController`, поверх которого сейчас
не открыт другой экран. SDK покажет проверку модально. Пример закрывает именно
экран SDK, а не навигацию вашего приложения.

```swift
import UIKit
import VerifSDK

@MainActor
func showVerification(
    from navigationController: UINavigationController,
    configuration: VerifSessionConfiguration,
    onResult: @escaping (VerifResult) -> Void,
    onFailure: @escaping (Error) -> Void
) {
    guard navigationController.viewIfLoaded?.window != nil,
          navigationController.presentedViewController == nil else {
        return
    }

    Verif.start(
        configuration: configuration,
        navigationController: navigationController,
        onFlowFinished: { [weak navigationController] result in
            navigationController?.presentedViewController?.dismiss(animated: true)
            onResult(result)
        },
        onError: { [weak navigationController] error in
            navigationController?.presentedViewController?.dismiss(animated: true)
            onFailure(error)
        }
    )
}
```

Вызывайте эту функцию после появления экрана приложения, например из кнопки.
Не передавайте невидимый navigation controller: для него SDK заменит содержимое
стека, а не покажет модальный экран.

## 5. Обработайте результат и ошибку

Подключите **оба** обработчика:

| Обработчик | Когда вызывается |
| --- | --- |
| `onFlowFinished` | Пользователь завершил экран проверки или отменил её. Аргумент — `VerifResult`. |
| `onError` | Проверка остановлена из-за технической ошибки. Аргумент — `Error`. |

В `onFlowFinished` разберите результат:

```swift
func message(for result: VerifResult) -> String {
    switch result {
    case .approved:
        return "Проверка пройдена"
    case .rejected(_):
        return "Проверка не пройдена"
    case .cancelled:
        return "Пользователь закрыл проверку"
    case .error(_):
        return "Не удалось завершить проверку"
    }
}
```

В `onError` закройте SDK и предложите повторить попытку. Не рассчитывайте, что эта
ошибка обязательно придёт ещё и в `onFlowFinished`. SDK **не закрывает экран сам** —
это делают обработчики в примерах. Если следом нужно показать alert или другой
экран, дождитесь окончания закрытия: `onDismiss` в SwiftUI или `completion` у UIKit `dismiss`.

Загрузка фото ещё не означает успешную проверку. Пока сервер обрабатывает данные,
SDK показывает ожидание; отдельного публичного результата `pending` нет.
`.approved` означает одобрение, а не просто отправку файлов. Техническую
недоступность проверки не трактуйте как отказ пользователю.

## Если сессия успела истечь

Необязательный обработчик `refreshSession` позволяет получить новую сессию через
ваш сервер. Например, при создании конфигурации:

```swift
func configurationWithRenewal(
    session: SdkSessionCredentials,
    fetchReplacement: @escaping @Sendable () async throws -> SdkSessionCredentials
) -> VerifSessionConfiguration {
    VerifSessionConfiguration(
        session: session,
        baseURL: URL(string: "https://api.dev.verif-online.ru")!,
        refreshSession: fetchReplacement
    )
}
```

`fetchReplacement` — функция **вашего приложения**, не готовый метод SDK. Она должна
вернуть сессию **той же проверки, того же пользователя и того же окружения**.
При неудаче выбросите ошибку; не делайте бесконечный цикл запросов. Обработчик
должен поддерживать отмену запроса при закрытии SDK.

Без него истечение токена или отказ авторизации завершат попытку ошибкой.
После обновления SDK повторяет отклонённый API-запрос не более одного раза.
Обновление не гарантирует продолжение уже начатой загрузки: если сервер больше
не принимает её, может понадобиться повторить шаг.

## Локальные строки SDK

`locale: Locale(identifier: "ru")` выбирает русский язык, `"en"` — английский.
Без явного `locale` выбор зависит от локализаций приложения. Для замены отдельных
надписей используйте именованные поля `VerifLocalizationOverrides`:

```swift
func configurationWithCustomText(
    session: SdkSessionCredentials
) -> VerifSessionConfiguration {
    VerifSessionConfiguration(
        session: session,
        baseURL: URL(string: "https://api.dev.verif-online.ru")!,
        locale: Locale(identifier: "ru"),
        localizationOverrides: .init(
            common: .init(next: "Продолжить"),
            consent: .init(navigationTitle: "Проверка личности")
        )
    )
}
```

Передавайте только нужные замены. Остальные надписи останутся стандартными.
`nil`, пустая строка и строка из одних пробелов не заменяют встроенный текст.
Переданные строки SDK не переводит: язык замен выбираете вы.

Настройки не меняют тексты с сервера и системный запрос камеры. Изменения применяются
при следующем запуске SDK, не к уже открытому экрану. Открывайте **только одну
проверку одновременно**: языковые настройки сейчас общие.

## Цвета SDK

Меняйте нужные поля структуры `VerifTheme.Palette` и передавайте тему в конфигурацию:

```swift
import SwiftUI
import VerifSDK

func configurationWithCustomColors(
    session: SdkSessionCredentials
) -> VerifSessionConfiguration {
    var theme = VerifTheme.default
    theme.palette.primaryButtonBackground = Color("VerificationButton", bundle: .main)
    theme.palette.primaryButtonForeground = Color("VerificationOnButton", bundle: .main)
    theme.palette.link = Color("VerificationLink", bundle: .main)

    return VerifSessionConfiguration(
        session: session,
        baseURL: URL(string: "https://api.dev.verif-online.ru")!,
        theme: theme
    )
}
```

Сначала создайте эти три Color Set в `Assets.xcassets` приложения. Для каждого
задайте варианты **Any/Dark**: SDK использует адаптивный `Color`, отдельные
`lightColors`/`darkColors` не нужны. Для ресурсов другого модуля укажите его bundle.

| Что настроить | Поле `theme.palette` |
| --- | --- |
| Фон экранов и карточек | `background`, `surface` |
| Основной и второстепенный текст | `primaryText`, `secondaryText` |
| Фон и текст включённой основной кнопки | `primaryButtonBackground`, `primaryButtonForeground` |
| Ссылка согласия | `link` |
| Значок документа и фон под ним | `documentStep`, `documentStepBackground` |
| Значок селфи и фон под ним | `selfieStep`, `selfieStepBackground` |
| Успешный результат и ошибка | `success`, `error` |

Остальные цвета можно не задавать. Без замены новых ролей сохраняется прежний вид:
кнопка следует `primaryText` / `background`, ссылка — `documentStep`, селфи — `success`.
Фон значка — его акцент с прозрачностью 0.12. Неактивная кнопка использует
`surfaceMuted` и приглушённый `primaryText`. `accentStart` / `accentEnd` не управляют кнопкой.

## Обновление с 0.1.x

В 0.2.0 дизайн-система включена в основной фреймворк. В коде приложения оставьте
только `import VerifSDK`. Прямые `import VerifSDKDesignSystem` удалите, а имена вида
`VerifSDKDesignSystem.VerifTheme` замените на `VerifTheme` после импорта SDK.

При ручной интеграции удалите старый `VerifSDKDesignSystem.xcframework` из зависимостей
приложения: новая поставка содержит только `VerifSDK.xcframework` и
`VerifSDKResources.bundle`. Не подключайте старую и встроенную дизайн-систему одновременно.
Готовые бинарные обёртки над SDK необходимо пересобрать с 0.2.0. Обычно код,
который использовал только `import VerifSDK`, менять не нужно, но приложение тоже
нужно пересобрать. Обновление не меняет формат серверной сессии или адреса API.

## Перед выпуском приложения

- Пройдите проверку на реальном iPhone: камера, документ, селфи и завершение.
- Проверьте запрет камеры, потерю сети, отмену и истечение сессии.
- Убедитесь, что обработчики закрывают SDK и не запускают его заново автоматически.
- Проверьте обе темы, большой системный шрифт и нужные языки.
- Для production используйте production-адрес и соответствующую сессию.

Если новые настройки не находятся в автодополнении, проверьте версию пакета:
обновление README не обновляет скачанный бинарный SDK.

Для старых интеграций сохранён подписанный вход `VerifConfiguration.sdkInit`.
В новой интеграции используйте готовую сессию, как описано выше.
