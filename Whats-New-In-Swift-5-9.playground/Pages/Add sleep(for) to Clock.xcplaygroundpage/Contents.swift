/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Add sleep(for:) to Clock

[SE-0374](https://github.com/apple/swift-evolution/blob/main/proposals/0374-clock-sleep-for.md) adds a new extension method to Swift’s `Clock` protocol that allows us to suspend execution for a set number of seconds, but also extends duration-based `Task` sleeping to support a specific tolerance.

The `Clock` change is a small but important one, particularly if you’re mocking a concrete `Clock` instance to remove delays in tests that would otherwise exist in production.

For example, this class can be created with any kind of `Clock`, and will sleep using that clock before triggering a save operation:
*/
import Foundation

class DataController: ObservableObject {
    var clock: any Clock<Duration>
    
    init(clock: any Clock<Duration>) {
        self.clock = clock
    }
    
    func delayedSave() async throws {
        try await clock.sleep(for: .seconds(1))
        print("Saving…")
    }
}
/*:
Because that uses `any Clock<Duration>`, it’s now possible to use something like `ContinuousClock` in production but your own `DummyClock` in testing, where you ignore all `sleep()` commands to keep your tests running quickly.

In older versions of Swift the equivalent code would in theory have been `try await clock.sleep(until: clock.now.advanced(by: .seconds(1)))`, but that wouldn’t work in this example because `clock.now` isn’t available as Swift doesn’t know exactly what kind of clock has been used.

As for the change to `Task` sleeping, it means we can go from code like this:
*/
try await Task.sleep(until: .now + .seconds(1), tolerance: .seconds(0.5))
/*:
To just this:
*/
try await Task.sleep(for: .seconds(1), tolerance: .seconds(0.5))
/*:

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/