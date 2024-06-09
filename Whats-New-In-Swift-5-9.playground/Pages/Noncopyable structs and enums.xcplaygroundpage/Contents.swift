/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Noncopyable structs and enums

[SE-0390](https://github.com/apple/swift-evolution/blob/main/proposals/0390-noncopyable-structs-and-enums.md) introduces the concept of structs and enums that cannot be copied, which in turn allows a single instance of a struct or enum to be shared in many places – they still ultimately have one owner, but can now be accessed in various parts of your code.

First, this change introduces new syntax to suppress a requirement: `~Copyable`. That means “this type cannot be copied”, and this suppression syntax is not available elsewhere at this time – we can’t use `~Equatable`, for example, to opt out of `==` for a type.

So, we could create a new noncopyable `User` struct like this:
*/
struct User: ~Copyable {
    var name: String
}
/*:
Note: Noncopyable types cannot conform to any protocols other than `Sendable`.

Once you create a `User` instance, its noncopyable nature means that it’s used very differently from previous versions of Swift. For example, this kind of code might read like nothing special:
*/
func createUser() {
    let newUser = User(name: "Anonymous")
    
    var userCopy = newUser
    print(userCopy.name)
}
    
createUser()
/*:
But we’ve declared the `User` struct as being noncopyable – how can that take a copy of `newUser`? The answer is that it *can’t*: assigning `newUser` to `userCopy` causes the original `newUser` value to be *consumed*, which means it can no longer be used because ownership now belongs to `userCopy`. If you try changing `print(userCopy.name)` to `print(newUser.name)` you’ll see Swift throws up a compiler error – it’s just not allowed.

New restrictions also apply to how we use noncopyable types as function parameters: [SE-0377](https://github.com/apple/swift-evolution/blob/main/proposals/0377-parameter-ownership-modifiers.md) says that functions must specify whether they intend to consume the value and therefore render it invalid at the call site after the function finishes, or whether they want to *borrow* the value so that they can read all its data at the same time as other borrowing parts of our code.

So, we could write one function that creates a user, and another function that *borrows* the user to gain read-only access to its data:
*/
func createAndGreetUser() {
    let newUser = User(name: "Anonymous")
    greet(newUser)
    print("Goodbye, \(newUser.name)")
}
    
func greet(_ user: borrowing User) {
    print("Hello, \(user.name)!")
}
    
createAndGreetUser()
/*:
In contrast, If we had made the `greet()` function use `consuming User` then the `print("Goodbye, \(newUser.name)")` would not be allowed – Swift would consider the `newUser` value to be invalid after `greet()` has run. On the flip side, because consuming methods must end the lifetime of the object, they can mutate its properties freely.

This shared behavior gives noncopyable structs a superpower that was previously restricted to classes and actors: we can give them deinitializers that will automatically be run when the final reference to a noncopyable instance is destroyed. For example, this struct prints a message when it's destroyed:
*/
struct Movie: ~Copyable {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    deinit {
        print("\(name) is no longer available")
    }
}
    
func watchMovie() {
    let movie = Movie(name: "The Hunt for Red October")
    print("Watching \(movie.name)")
}
    
watchMovie()
/*:
When that runs it prints “Watching The Hunt for Red October” then “The Hunt for Red October is no longer available”. 

Methods inside a noncopyable type are borrowing by default, but they can be marked as `mutating` just like copyable types, and they can also be marked as *consuming* to mean that the value is invalid after the method has been run.

As an example, you might know the movie and TV series Mission Impossible, where secret agents are given their mission instructions in a self-destructing tape that can be played only once. This is perfect for a consuming method like this:
*/
struct MissionImpossibleMessage: ~Copyable {
    private var message: String
    
    init(message: String) {
        self.message = message
    }
    
    consuming func read() {
        print(message)
    }
}
/*:
That marks the message itself as private, so it can only be access by calling the `read()` method that consumes the instance.

Unlike mutating methods, consuming methods can be run on constant instances of your type. So, code like this is fine:
*/
func createMessage() {
    let message = MissionImpossibleMessage(message: "You need to abseil down a skyscraper for some reason.")
    message.read()
}
    
createMessage()
/*:
- important:  Because `message.read()` consumes the `message` instance, it is an error to attempt to call `message.read()` a second time.

Consuming methods are made a little more complex when combined with deinitializers because they might double up on any clean up work you do. For example, if you were tracking high scores in a game you might want to have a consuming `finalize()` method that writes the latest high score to permanent storage and stops anyone else from changing the score further, but you might *also* have a deinitializer that saves the latest score to disk when the object is destroyed.

To avoid this problem, Swift 5.9 introduces a new `discard` operator that can be used on consuming methods of noncopyable types. When you use `discard self` in a consuming method, it stop the deinitializer from being run for this object.

So, we could implement our `HighScore` struct like this:
*/
struct HighScore: ~Copyable {
    var value = 0
    
    consuming func finalize() {
        print("Saving score to disk…")
        discard self
    }
    
    deinit {
        print("Deinit is saving score to disk…")
    }
}
    
func createHighScore() {
    var highScore = HighScore()
    highScore.value = 20
    highScore.finalize()
}
    
createHighScore()
/*:
There are a few extra complexities you need to be aware of when working with this new functionality:

- Classes and actors cannot be noncopyable.
- Noncopyable types don’t support generics at this time, which rules out optional noncopyable objects and also arrays of noncopyable objects for the time being.
- If you use a noncopyable type as a property inside another struct or enum, that parent struct or enum must also be noncopyable.
- You need to be very careful adding or removing `Copyable` from existing types, because it dramatically changes how they are used. If you’re shipping code in a library, this will break your ABI.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/