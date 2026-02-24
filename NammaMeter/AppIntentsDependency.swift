#if canImport(AppIntents)
import AppIntents

// Keeps an explicit AppIntents module dependency so metadata processing does not
// warn during test builds when no concrete intents are defined yet.
private let _appIntentsDependencyAnchor: (any AppIntent.Type)? = nil
#endif
