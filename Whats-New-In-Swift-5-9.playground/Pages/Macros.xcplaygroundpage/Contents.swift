/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# Macros

[SE-0382](https://github.com/apple/swift-evolution/blob/main/proposals/0382-expression-macros.md), [SE-0389](https://github.com/apple/swift-evolution/blob/main/proposals/0389-attached-macros.md), and [SE-0397](https://github.com/apple/swift-evolution/blob/main/proposals/0397-freestanding-declaration-macros.md) combine to add macros to Swift, which allow us to create code that transforms syntax at compile time.

Macros in something like C++ are a way to pre-process your code – to effectively perform text replacement on the code before it’s seen by the main compiler, so that you can generate code you really don’t want to write by hand.

Swift’s macros are similar, but significantly more powerful – and thus also significantly more complex. They also allow us to dynamically manipulate our project’s Swift code before it’s compiled, allowing us to inject extra functionality at compile time.

The key things to know are:

- They are type-safe rather than simple string replacements, so you need to tell your macro exactly what data it will work with.
- They run as external programs during the build phase, and do not live in your main app target.
- Macros are broken down into multiple smaller types, such as `ExpressionMacro` to generate a single expression, `AccessorMacro` to add getters and setters, and `ConformanceMacro` to make a type conform to a protocol.
- Macros work with your parsed source code – we can query individual parts of the code, such as the name of a property we’re manipulating or it types, or the various properties inside a struct.
- They work inside a sandbox and must operate only on the date they are given.

That last part is particularly important: Swift’s macros support are built around Apple’s SwiftSyntax library for understanding and manipulating source code. You must add this as a dependency for your macros.

Let’s start with a simple macro, so you can see how they work. Because macros are run at compile time, we can make a tiny macro that returns the date and time our app was built – a helpful thing to have in your debug diagnostics. This takes several steps, several of which should take place a separate module from your main target.

First we need to create the code that performs the macro expansion – the thing that will turn `#buildDate` into something like **2023-06-05T18:00:00Z**:
*/
public struct BuildDateMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        let date = ISO8601DateFormatter().string(from: .now)
        return "\"\(raw: date)\""
    }
}
/*:
**Important:** This code should *not* be in your main app target; we don’t want that code being compiled into our finished app, we just want the finished date string in there.

Inside that same module we create a struct that conforms to the `CompilerPlugin` protocol, exporting our macro:
*/
import SwiftCompilerPlugin
import SwiftSyntaxMacros
    
@main
struct MyMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BuildDateMacro.self
    ]
}
/*:
We would then add that to our list of targets in Package.swift:
*/
.macro(
  name: "MyMacrosPlugin",
  dependencies: [
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
    .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
  ]
),
/*:
That finishes *creating* the macro in an external module. The rest of our code takes place wherever we want to *use* the macro, such as in our main app target. 

This takes two steps, starting with a definition of what the macro is. In our case this is a free-standing expression macro that will return a string, it exists inside the `MyMacrosPlugin` module, and has the strict name `BuildDateMacro`. So, we’d add this definition to our main target:
*/
@freestanding(expression)
macro buildDate() -> String =
  #externalMacro(module: "MyMacrosPlugin", type: "BuildDateMacro")
/*:
And the second step is to actually use the macro, like this:
*/
print(#buildDate)
/*:
When you read through this code, the most important thing to take away is that the main macro functionality – all that code inside the `BuildDateMacro` struct – is run at build time, with its results being injected back into the call sites. So, our little `print()` call above would be rewritten to something like this:
*/
print("2023-06-05T18:00:00Z")
/*:
This in turn means the code inside your macros can be as complex as you need: we could have crafted our date in any way we wanted, because all that finished code actually sees is the string we returned.

Now, in practice the Swift team recommends *against* this kind of macro, because they want us to build things with consistent output – they prefer macros that produce the same output given the same output, because it allows things like incremental builds to function efficiently.

Let’s try a slightly more useful macro, this time making a *member attribute* macro. When applied to a type such as a class, this lets us apply an attribute to every member in a class. This is identical in concept to the older `@objcMembers` attribute, which adds `@objc` to each of the properties in a type.

For example, if you have an observable object that uses `@Published` on every one of its properties, you could write a simple `@AllPublished` macro that does the job for you. First, write the macro itself:
*/
public struct AllPublishedMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        [AttributeSyntax(attributeName: SimpleTypeIdentifierSyntax(name: .identifier("Published")))]
    }
}
/*:
Second, include that in your list of provided macros:
*/
struct MyMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BuildDateMacro.self,
        AllPublishedMacro.self,
    ]
}
/*:
Third, declare the macro in your main app target, this time marking it as an attached member-attribute macro:
*/
@attached(memberAttribute)
macro AllPublished() = #externalMacro(module: "MyMacrosPlugin", type: "AllPublishedMacro")
/*:
And now use it to annotate your observable object class:
*/
@AllPublished class User: ObservableObject {
    var username = "Taylor"
    var age = 26
}
/*:
Our macros are able to accept parameters to control their behavior, although here it’s easy for the complexity to really shoot upwards. As an example, Doug Gregor from the Swift team maintains [a small GitHub repository of example macros](https://github.com/DougGregor/swift-macro-examples), including one neat one that checks hard-coded URLs are valid at build time – it becomes impossible to type a URL wrongly, because the build won’t proceed.

Declaring the macro in our app target is straightforward, including adding a string parameter:
*/
@freestanding(expression) public macro URL(_ stringLiteral: String) -> URL = #externalMacro(module: "MyMacrosPlugin", type: "URLMacro")
/*:
Using it is also straightforward:
*/
let url = #URL("https://swift.org")
print(url.absoluteString)
/*:
That makes `url` into a full `URL` instance rather than an optional one, because we will have checked the URL is correct at compile time.

What’s harder is the actual macro itself, which needs to read the "https://swift.org" string that was passed in and convert it into a URL. Doug’s version is more thorough, but if we boil it down to the bare minimum we get this:
*/
public struct URLMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression,
              let segments = argument.as(StringLiteralExprSyntax.self)?.segments
        else {
            fatalError("#URL requires a static string literal")
        }
    
        guard let _ = URL(string: segments.description) else {
            fatalError("Malformed url: \(argument)")
        }
    
        return "URL(string: \(argument))!"
    }
}
/*:
SwiftSyntax is marvelous, but it’s not what I’d call *discoverable*.

There are three more things I want to add before moving on.

First, the `MacroExpansionContext` value we’re given has a very helpful `makeUniqueName()` method, which will produce a new variable name that’s guaranteed not to conflict with any other names in the current context. If you’re looking to inject new names into the finished code, `makeUniqueName()` is a smart move.

Second, one of the concerns with macros is the ability to debug your code when you hit a problem – it’s hard to trace what’s going on when you can’t actually step through code easily. [Some work has already taken place inside SourceKit](https://github.com/apple/swift/pull/62425) to expand macros as a refactoring operation, but really we need to see what ships in Xcode.

And finally, the extensive transformations that macros enable may mean that Swift Evolution itself will evolve over the next year or two, because so many features that might previously have required extensive compiler support and discussion can now be prototyped and perhaps even shipped using macros.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/