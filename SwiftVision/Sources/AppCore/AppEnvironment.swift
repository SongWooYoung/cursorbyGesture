import Config
import Foundation

public struct AppEnvironment {
    public let config: AppConfig

    public init(config: AppConfig) {
        self.config = config
    }
}
