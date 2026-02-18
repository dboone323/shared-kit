actor CompletionState {
    var isFinished = false
    func finish() { isFinished = true }
    func check() -> Bool { isFinished }
}
