public enum AppLogger {
    public static func log(_ message: String) -> String {
        // For testability, return the message instead of printing.
        "[SharedKit] " + message
    }
}
