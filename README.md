# VerifSDK

VerifSDK — бинарный Swift Package для встраивания проверки в iOS-приложение.
Package product: `VerifSDK`; публичный импорт: `VerifSDK`.

## Установка

В Xcode выберите **File → Add Package Dependencies…**, укажите
`https://github.com/verif-online/msdk-ios` и добавьте продукт `VerifSDK`.
Для SwiftPM manifest используйте версию `0.1.0`.

Package объявляет минимальную платформу iOS 16. Бинарные XCFramework и чистый
consumer package проверялись при сборке на Xcode 27 и Xcode 26.6; runtime
проверки выполнялись на iOS 27. Совместимость runtime на iOS 16 отдельно не
проверена. Эти проверки не означают полного production acceptance всех
серверных профилей и сценариев.

Ресурсы локализации автоматически включены в продукт через SwiftPM resource
carrier. Отдельно копировать `VerifSDKResources.bundle` или регистрировать его
в приложении не нужно.

Подготовка credentials, запуск SwiftUI/UIKit и обработка исходов описаны в
[руководстве по интеграции](Docs/Usage.md).
