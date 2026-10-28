# Руководство по интеграции VerifSDK

## Подключение

В Xcode выберите **File → Add Package Dependencies…**, укажите
`https://github.com/verif-online/msdk-ios`, выберите версию `0.1.1` и добавьте
продукт **VerifSDK** в приложение. Минимальная версия iOS — 16.0.

```swift
import VerifSDK
```

Ресурсы и дизайн-система подключаются вместе с продуктом. Копировать bundle
вручную или добавлять другие imports не нужно.

Добавьте разрешение камеры в `Info.plist` приложения:

```xml
<key>NSCameraUsageDescription</key>
<string>Камера нужна для съёмки документа и селфи.</string>
```

## Получение сессии

Сервер вашего приложения вызывает `POST /sdk/init` и передаёт приложению
`token` и `expiresAt`. Подпись и API-ключи остаются на сервере. SDK получает
готовую сессию и сам `/sdk/init` не вызывает.

Преобразуйте `expiresAt` из ответа вашего сервера в абсолютный `Date`:

```swift
let session = try SdkSessionCredentials(
    token: response.token,
    expiresAt: response.expiresAt
)
```

`response` — модель вашего приложения, в которой `expiresAt` уже имеет тип
`Date`; это не тип SDK. Токен можно передать без префикса или с `Bearer `.
Не сохраняйте токены в логи, аналитику или пользовательские настройки.

## Настройка окружения

По умолчанию используется `https://api.verif-online.ru`. Для dev задайте URL явно:

```swift
let configuration = VerifSessionConfiguration(
    session: session,
    baseURL: URL(string: "https://api.dev.verif-online.ru")!,
    locale: Locale(identifier: "ru")
)
```

Токен должен быть выпущен для выбранного окружения. Поддерживаются русский и
английский интерфейсы, светлая и тёмная темы. Без `locale` используется язык
приложения; `theme` по умолчанию равен `.default`.

## SwiftUI

Передайте готовую конфигурацию в экран приложения. Обработчик результата
закрывает SDK; при фатальной ошибке хост предоставляет явное закрытие.

```swift
import SwiftUI
import VerifSDK

@MainActor
struct VerificationHostView: View {
    let configuration: VerifSessionConfiguration
    let onResult: (VerifResult) -> Void

    @State private var isPresented = false
    @State private var didStart = false
    @State private var hasError = false

    var body: some View {
        Button("Начать проверку") {
            didStart = true
            isPresented = true
        }
        .disabled(didStart)
        .fullScreenCover(isPresented: $isPresented) {
            ZStack(alignment: .topTrailing) {
                Verif.start(
                    configuration: configuration,
                    onFlowFinished: { result in
                        isPresented = false
                        onResult(result)
                    },
                    onError: { _ in
                        hasError = true
                    }
                )

                if hasError {
                    Button("Закрыть") {
                        isPresented = false
                    }
                    .padding()
                }
            }
        }
    }
}
```

Для следующей попытки получите новую сессию и создайте новый экран запуска.
Строки интерфейса хоста локализуются самим приложением.

## UIKit

Передайте видимый `UINavigationController`:

```swift
import UIKit
import VerifSDK

@MainActor
func startVerification(
    configuration: VerifSessionConfiguration,
    from navigationController: UINavigationController,
    onFinished: @escaping (VerifResult) -> Void,
    onError: @escaping (Error) -> Void
) {
    Verif.start(
        configuration: configuration,
        navigationController: navigationController,
        onFlowFinished: onFinished,
        onError: onError
    )
}
```

При завершении хост обновляет своё состояние и закрывает презентацию SDK.
При `onError` штатный экран ошибки остаётся показанным: предоставьте пользователю
возможность закрыть его. Callback сам не закрывает SDK.

## Обновление токена

Можно передать необязательный `refreshSession`. Это async callback приложения,
который получает с вашего сервера новую сессию той же проверки:

```swift
@MainActor
func makeConfiguration(
    session: SdkSessionCredentials,
    refresh: @escaping @Sendable () async throws -> SdkSessionCredentials
) -> VerifSessionConfiguration {
    VerifSessionConfiguration(
        session: session,
        refreshSession: refresh
    )
}
```

Сервер хоста снова вызывает `/sdk/init`; аппликант, процесс и окружение должны
остаться прежними. SDK запрашивает обновление при истечении срока или API `401`.
Параллельные запросы используют одно обновление; запрос после `401` повторяется
не более одного раза. Callback должен поддерживать отмену.

Без callback либо при его ошибке текущая попытка завершается через `onError`.
Не возвращайте просроченный или уже отклонённый токен. Продолжение начатой загрузки
после новой серверной сессии зависит от правил backend для выданного `mediaId`;
SDK не создаёт новый upload intent незаметно для приложения.

## Результаты

- `.approved` — проверка одобрена.
- `.rejected(reason:)` — проверка отклонена; причина может отсутствовать.
- `.cancelled` — пользователь отменил проверку.
- `.error(Error)` — ошибка или отдельный финальный исход.

Фатальная ошибка приходит только в `onError`: следующий `onFlowFinished` для
неё не вызывается. Это не пользовательский отказ. Серверный исход `UNAVAILABLE`
приходит через `onFlowFinished(.error(...))`; при необходимости его можно
отличить по точному `error.localizedDescription == "VERIFICATION_UNAVAILABLE"`.
Не выводите остальные payload ошибки, токен или ответ сервера в логи.

## Совместимость с 0.1.0

Существующий запуск через `SdkInitCredentials` и `VerifConfiguration` сохранён.
Для новых интеграций используйте готовую сессию, как описано выше.
