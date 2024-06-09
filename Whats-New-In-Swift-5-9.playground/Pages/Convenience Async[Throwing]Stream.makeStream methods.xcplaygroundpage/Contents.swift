/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Convenience Async[Throwing]Stream.makeStream methods

[SE-0388](https://github.com/apple/swift-evolution/blob/main/proposals/0388-async-stream-factory.md) adds a new `makeStream()` method to both `AsyncStream` and `AsyncThrowingStream` that sends back both the stream itself alongside its continuation. 

So, rather than writing code like this:
*/
var _continuation: AsyncStream<String>.Continuation!
let stream = AsyncStream<String> { _continuation = $0 }
let continuation = _continuation!
/*:
We can now get both at the same time:
*/
let (newStream, newContinuation) = AsyncStream.makeStream(of: String.self)
/*:
This is going to be particularly welcome in places where you need to access the continuation outside of the current context, such as in a different method. For example, previously we might have written a simple number generator like this one, which needs to store the continuation as its own property in order to be able to call it from the `queueWork()` method:
*/
struct OldNumberGenerator {
    private var continuation: AsyncStream<Int>.Continuation!
    var stream: AsyncStream<Int>!
    
    init() {
        stream = AsyncStream(Int.self) { continuation in
            self.continuation = continuation
        }
    }
    
    func queueWork() {
        Task {
            for i in 1...10 {
                try await Task.sleep(for: .seconds(1))
                continuation.yield(i)
            }
    
            continuation.finish()
        }
    }
}
/*:
With the new `makeStream(of:)` method this code becomes much simpler:
*/
struct NewNumberGenerator {
    let (stream, continuation) = AsyncStream.makeStream(of: Int.self)
    
    func queueWork() {
        Task {
            for i in 1...10 {
                try await Task.sleep(for: .seconds(1))
                continuation.yield(i)
            }
    
            continuation.finish()
        }
    }
}
/*:

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/