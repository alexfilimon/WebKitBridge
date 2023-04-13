# WebKitBridge

Package for working with `WKWebView` and for communicating between JS and Swift.

## Proper configuration

`WebKitBridgeViewController` class have constructor with two params:
- configuration
- delegate

Configuration provide a lot of possibilities for customizing your webview:
- design through desigh config (color and animation duration)
- URL for opening
- spinner manager for showing spinner while loading for users
- array of income events and scripts provider (events JS -> Swift)
- custom user agent
- views provider - customize view for no internet state and view for loading state
- reachability service - handling no internet state
- navigation item modifier

## How to add outcome event (Swift -> JS)

Just realize protocol `WebKitBridgeOutcomeEvent` and call method `run(outcomeEvent:)` in `WebKitBridgeViewController` class

## How to add income event (JS -> Swift)

- Realize protocol `WebKitBridgeIncomeEvent`
- Make some actions when method `fire` will be called by system
- Pass these new protocol realization to configuration when `WebKitBridgeViewController` is initializing
