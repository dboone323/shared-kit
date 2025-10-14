import Foundation

@main
struct Phase8GMain {
    static func main() async {
        await Phase8GDemos.runComposedQSEQENDemo()
        // Optionally run all demos (some rely on broader SharedKit types)
        // await Phase8GDemos.runAllDemos()
    }
}
