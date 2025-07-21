# Changelog

## 0.1.16 (2025-07-21)

Full support for PATCH calls to notices-served and privacy-preferences APIs


## 0.1.15 (2025-07-02)

- fix crash on Android when creating TCF view (occurred when webview was garbage collected during open)
- fix powered by footer on iOS not opening on non TCF view


## 0.1.14 (2025-06-24)

- Custom logging support (JanusLogger interface and Janus.setLogger method)
- UI improvements and dark mode fixes


## 0.1.13 (2025-06-16)

- fix iOS rotation bug in TCF experience
- prevent experience from being shown multiple times concurrently


## 0.1.12 (2025-06-06)

- Privacy experience API call updates to increase cacheability and consistency
- Better support for links (Privacy Policy, etc) in TCF experiences


## 0.1.11 (2025-06-04)

Loading of TCF consent screen in the background


## 0.1.10 (2025-05-23)


## 0.1.9 (2025-05-16)

- add autoShowExperience configuration to Janus
- fix layout issue on iPad when
- fix for older iOS versions


## 0.1.8 (2025-05-12)

- add privacy center host configuration option for TCF presentation


## 0.1.7 (2025-05-02)

- fix issue with Flutter SDK building example app


## 0.1.6 (2025-05-02)

- fix for fidesString not being written on Janus in certain configurations
- fix JSON decoding init preventing initialization in certain configurations
- fix for shouldShowExperience and automatically showing the experience on TCF experiences


## 0.1.5 (2025-04-27)

WebView support using webview_flutter
region/getLocationByIPAddress calls in Flutter
Full Flutter Example app
ConsentMethod/ConsentMetadata Android bug
Events from Native SDKs->Flutter working on both iOS and Android


## 0.1.4 (2025-04-19)

Get rid of webHost in JanusConfiguration


## 0.1.3 (2025-04-19)

fix Flutter version requirements


## 0.1.2 (2025-04-19)

Updated documentation


## 0.1.1 (2025-04-19)

Setup Flutter publishing


## 0.0.1 - 2024-05-15

* Initial release
* Core functionality for privacy consent management
* Integration with native Janus SDKs for Android and iOS
* WebView integration support
* Event listening support
