/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# consume operator to end the lifetime of a variable binding

[SE-0366](https://github.com/apple/swift-evolution/blob/main/proposals/0366-move-function.md) extends the concept of consuming values to local variables and constants of copyable types, which might benefit developers who want to avoid excess retain/release calls happening behind the scenes as their data is passed around.

In its simplest form, the `consume` operator looks like this:
*/
struct User {
    var name: String
}
    
func createUser() {
    let newUser = User(name: "Anonymous")
    let userCopy = consume newUser
    print(userCopy.name)
}
    
createUser()
/*:
The important line there is the `let userCopy` line, which does two things at once:

1. It copies the value from `newUser` into `userCopy`.
2. It ends the lifetime of `newUser`, so any further attempt to access it will throw up an error.

This allows us to tell the compiler explicitly “do not allow me to use this value again,” and it will enforce the rule on our behalf.

I can see this being particularly common with the so-called black hole, `_`, where we don’t want a copy of the data but simply want to mark it as being destroyed, like this:
*/
func consumeUser() {
    let newUser = User(name: "Anonymous")
    _ = consume newUser
}
/*:
In practice, though, it’s possible the most common place the `consume` operator will be used is when passing values into a function like this:
*/
func createAndProcessUser() {
    let newUser = User(name: "Anonymous")
    process(user: consume newUser)
}
    
func process(user: User) {
    print("Processing \(user.name)…")
}
    
createAndProcessUser()
/*:
There are two extra things I think are particularly worth knowing about this feature.

First, Swift tracks which branches of your code have consumed values, and enforces the rules conditionally. So, in this code only one of the two possibilities consumes our `User` instance:
*/
func greetRandomly() {
    let user = User(name: "Taylor Swift")
    
    if Bool.random() {
        let userCopy = consume user
        print("Hello, \(userCopy.name)")
    } else {
        print("Greetings, \(user.name)")
    }
}
    
greetRandomly()
/*:
Second, technically speaking `consume` operates on *bindings* not *values*. In practice this means if we consume using a variable, we can reinitialize the variable and use it just fine:
*/
func createThenRecreate() {
    var user = User(name: "Roy Kent")
    _ = consume user
    
    user = User(name: "Jamie Tartt")
    print(user.name)
}
    
createThenRecreate()
/*:

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/