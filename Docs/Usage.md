# Руководство по интеграции VerifSDK

Это руководство описывает публичный API бинарного SwiftPM-пакета `VerifSDK`
версии `0.1.0`. Приложение получает подписанные init-данные от собственного
backend, создаёт `SdkInitCredentials` и передаёт результат в `Verif.start`.

## Установка

В Xcode выберите **File → Add Package Dependencies…**, введите
`https://github.com/verif-online/msdk-ios`, выберите версию `0.1.0` и добавьте
единственный продукт `VerifSDK` в target приложения.

```swift
import VerifSDK
```

Продукт объединяет `VerifSDK`, `VerifSDKDesignSystem` и SwiftPM target
`VerifSDKResourceCarrier`. Resource carrier автоматически копирует
`VerifSDKResources.bundle` в приложение. Отдельно копировать bundle или
вызывать регистрацию ресурсов не нужно: SDK находит его самостоятельно.
Отдельный `import VerifSDKDesignSystem` для использования `VerifTheme` не нужен.

## Подготовка init credentials

Секрет HMAC хранится только на сервере приложения. Сервер формирует и
подписывает init JSON, затем передаёт мобильному приложению подписанные
байты тела и значения `apiKey`, `timestamp`, `signature`. Не вычисляйте HMAC
в приложении и не помещайте секрет в бинарный файл, конфигурацию, логи или
аналитику.

Предпочтительный initializer принимает `signedBody: Data`. Передайте в него
те же байты UTF-8 JSON, которые сервер подписал: SDK отправляет тело без
повторной сериализации. В JSON должны присутствовать `applicantId`,
`flowId` (если предусмотрен) и `ttl`; initializer декодирует их для модели
credentials. Не разбирайте и не сериализуйте JSON заново между получением
подписанного тела и созданием credentials.

```swift
let issued = try await appBackend.issueVerificationInit(for: applicant)
// appBackend и его транспорт принадлежат приложению; это не API VerifSDK.

let credentials = try SdkInitCredentials(
    signedBody: issued.signedBody,
    apiKey: issued.apiKey,
    timestamp: issued.timestamp,
    signature: issued.signature
)
```

`issueVerificationInit` и тип `issued` здесь обозначают адаптер и модель
ответа вашего приложения. Имена endpoint, формат ответа и авторизация этого
адаптера определяются вашим backend-контрактом, а не SDK.

Typed initializer оставлен для обратной совместимости:

```swift
let credentials = SdkInitCredentials(
    applicantId: applicantId,
    flowId: flowId,
    apiKey: apiKey,
    timestamp: timestamp,
    signature: signature,
    ttl: ttl
)
```

В typed-варианте SDK сериализует тело init самостоятельно. Не используйте его,
если подпись рассчитана для конкретных raw JSON bytes.

## Окружения

По умолчанию `VerifConfiguration` использует рабочий URL
`https://api.verif-online.ru`. Для тестового приложения задайте dev URL явно:

```swift
let devConfiguration = VerifConfiguration(
    sdkInit: credentials,
    baseURL: URL(string: "https://api.dev.verif-online.ru")!
)
```

Используйте credentials и аппликантов соответствующего окружения. Не запускайте
демонстрационные сценарии с реальными production-данными. Не переключайте
окружение лишь заменой URL: API key, подпись и идентификаторы должны быть
выпущены для того же окружения.

## SwiftUI

Передайте уже подготовленные credentials в экран приложения. Код ниже
показывает запуск из корневого SwiftUI-экрана с полноэкранной презентацией.
`onFlowFinished` обрабатывает terminal result и закрывает presentation;
фатальная ошибка SDK идёт через `onError`, завершает текущую попытку и не
вызывает вслед за собой `onFlowFinished`. Экран ошибки остаётся открыт, пока
хост явно его не закроет.

```swift
import SwiftUI
import VerifSDK

struct VerificationHostView: View {
    let credentials: SdkInitCredentials

    @State private var isShowingVerification = false
    @State private var hasStartedVerification = false
    @State private var resultMessage: String?
    @State private var hasSDKError = false

    private var configuration: VerifConfiguration {
        VerifConfiguration(sdkInit: credentials)
    }

    var body: some View {
        VStack(spacing: 16) {
            Button("Начать проверку") {
                guard !hasStartedVerification else { return }
                hasStartedVerification = true
                isShowingVerification = true
            }
            .disabled(hasStartedVerification)

            if let resultMessage {
                Text(resultMessage)
            }

            if hasSDKError {
                Text("Не удалось продолжить проверку. Попробуйте позже или обратитесь в поддержку.")
            }
        }
        .fullScreenCover(isPresented: $isShowingVerification) {
            ZStack(alignment: .topTrailing) {
                Verif.start(
                    configuration: configuration,
                    onFlowStarted: {
                        resultMessage = nil
                        hasSDKError = false
                    },
                    onFlowFinished: { result in
                        resultMessage = describe(result)
                        isShowingVerification = false
                    },
                    onError: { _ in
                        // Не закрывайте SDK автоматически и не сохраняйте payload ошибки.
                        hasSDKError = true
                    }
                )

                if hasSDKError {
                    Button("Закрыть") {
                        isShowingVerification = false
                    }
                    .padding()
                }
            }
        }
    }

    private func describe(_ result: VerifResult) -> String {
        switch result {
        case .approved:
            return "Проверка пройдена."
        case .rejected:
            return "Проверка не пройдена."
        case .cancelled:
            return "Проверка отменена."
        case let .error(error):
            if error.localizedDescription == "VERIFICATION_UNAVAILABLE" {
                return "Проверка сейчас недоступна."
            }
            return "Не удалось завершить проверку."
        @unknown default:
            return "Получен неизвестный результат проверки."
        }
    }
}
```

В production-хосте замените строки интерфейса на локализованные тексты вашего
приложения. Не выводите `error.localizedDescription`, подпись, токен, raw body,
ответ сервера или персональные данные в логи. Кнопка «Закрыть» в примере —
явное решение host UI: callback ошибки сам не закрывает presentation.
После закрытия эта view не запускает повторную попытку; родительское приложение
должно получить свежие init credentials и создать новую host view/presentation.

## UIKit

Передайте видимый `UINavigationController`. В production SDK показывает flow
модально от него; обработка `onError` не должна автоматически закрывать экран
SDK.

```swift
import UIKit
import VerifSDK

@MainActor
func startVerification(
    from navigationController: UINavigationController,
    credentials: SdkInitCredentials,
    onFinished: @escaping (VerifResult) -> Void,
    onSDKError: @escaping () -> Void
) {
    let configuration = VerifConfiguration(sdkInit: credentials)

    Verif.start(
        configuration: configuration,
        navigationController: navigationController,
        onFlowFinished: { result in
            onFinished(result)
        },
        onError: { _ in
            // Сохраните штатный экран SDK; не закрывайте его автоматически.
            onSDKError()
        }
    )
}
```

После terminal callback приложение может обновить собственное состояние.
Не трактуйте `onError` как `.rejected`.

## Результаты и ошибки

Публичный `VerifResult` имеет четыре исхода:

- `.approved` — сервер сообщил об одобрении.
- `.rejected(reason:)` — сервер сообщил об отказе. `reason` может быть `nil`.
- `.cancelled` — пользователь отменил поток.
- `.error(Error)` — ошибка или отдельный terminal outcome, отображаемый SDK.

`UNAVAILABLE` не является пользовательским отказом и не добавляет новый case
в `VerifResult`. Совместимое представление —
`VerifResult.error(SDKError.serverError(message: "VERIFICATION_UNAVAILABLE"))`
и отдельный final UI SDK. `SDKError` — внутренняя реализация, не используйте
её как публичный тип для cast. В публичном фасаде маркер доступен как
`error.localizedDescription`; при необходимости различать этот outcome
проверяйте точное значение `VERIFICATION_UNAVAILABLE`, как в SwiftUI-примере.

В текущей реализации фатальная ошибка SDK передаётся через `onError`: для этой
попытки runtime-сессия завершается, вызывается только `onError`, а
`onFlowFinished` следом не вызывается. Экран штатной ошибки остаётся показанным.
Не трактуйте такой callback как `.rejected`; хост-приложение решает, когда
закрыть presentation, и должно явно предоставить это действие. Новая попытка
требует новых init credentials от backend и новой SDK presentation.

Это отличается от `UNAVAILABLE`: он не идёт через фатальный `onError`, а
показывается отдельным final UI и передаётся через
`onFlowFinished(.error(SDKError.serverError(message: "VERIFICATION_UNAVAILABLE")))`
после того, как пользователь завершит этот экран.

## Сессия и повторный запуск

Для каждой новой попытки получайте свежие init credentials через backend
приложения и создавайте новую SDK presentation. После `UNAUTHORIZED` текущая
runtime-сессия завершена; повторно использовать её token или запускать ещё один
flow с теми же credentials нельзя.
Не записывайте SDK token, init signature, raw signed body или их заголовки в
логи, crash reports, аналитику и пользовательские настройки. Для диагностики
используйте только безопасные категории ошибок без payload и персональных
данных.

## Разрешения и ресурсы

Добавьте в `Info.plist` приложения понятный `NSCameraUsageDescription`:
SDK использует камеру для получения изображения документа и селфи. Запрос
разрешения выполняется во время соответствующего шага.

```xml
<key>NSCameraUsageDescription</key>
<string>Камера нужна для съёмки документа и селфи.</string>
```

Не добавляйте
`NSMicrophoneUsageDescription` или разрешение на фотобиблиотеку только ради
SDK: текущий production flow не использует микрофон или API фотобиблиотеки.
Если само приложение использует такие API, добавьте нужные ключи по его
собственным требованиям.

При `locale: nil` SDK использует локализацию bundle, выбранную системой для
хоста. Доступны встроенные переводы интерфейса `ru` и `en`. Чтобы зафиксировать
язык для потока, задайте его через `VerifConfiguration(locale:)`:

```swift
let configuration = VerifConfiguration(
    sdkInit: credentials,
    locale: Locale(identifier: "ru")
)
```

Каталог типов и описания server requirements остаются серверными данными;
локаль отправляется серверу SDK для соответствующих ответов.

`VerifConfiguration(theme:)` принимает `VerifTheme`. По умолчанию используется
`.default` с цветами, адаптирующимися к light/dark appearance. При необходимости
можно настроить компоненты `VerifTheme.Palette` (цвета),
`VerifTheme.Typography` (шрифты) и `VerifTheme.Layout` (отступы и радиусы);
все поля и initializer-аргументы определены публичным API
`VerifSDKDesignSystem`, который re-export-ится через `VerifSDK`.

## Поддерживаемые требования

SDK API 1.0.0 поддерживает server requirements `DOCUMENT`, `DOCUMENT_FORM` и
`SELFIE`. `DOCUMENT_FORM` отображает поля, переданные сервером. `SELFIE`
означает получение и загрузку изображения селфи; это не подтверждение active
liveness, challenge или передачи видео. Набор шагов в конкретном запуске
определяется ответом backend, а поддержка требования сама по себе не
подтверждает acceptance каждого server-side профиля.

## Совместимость и проверка

Package manifest задаёт deployment target iOS 16.0. Бинарный пакет и чистый
consumer product проверялись на сборку с Xcode 27 и Xcode 26.6; runtime
сценарии проверялись на iOS 27. Runtime на iOS 16 не проверен. Это не является
заявлением о полном production acceptance всех четырёх MVP-профилей,
backend-сценариев, устройств или версий iOS.
