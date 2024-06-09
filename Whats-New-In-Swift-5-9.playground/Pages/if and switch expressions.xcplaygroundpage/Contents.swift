/*:


&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
# `if` and `switch` expressions

[SE-0380](https://github.com/apple/swift-evolution/blob/main/proposals/0380-if-switch-expressions.md) adds the ability for us to use `if` and `switch` as expressions in several situations. This produces syntax that will be a little surprising at first, but overall it does help reduce a little extra syntax in the language. 

As a simple example, we could set a variable to either “Pass” or “Fail” depending on a condition like this:
*/
let score = 800
let simpleResult = if score > 500 { "Pass" } else { "Fail" }
print(simpleResult)
/*:
Or we could use a `switch` expression to get a wider range of values like this:
*/
let complexResult = switch score {
    case ...300: "Fail"
    case 301...500: "Pass"
    case 501...800: "Merit"
    default: "Distinction"
}
    
print(complexResult)
/*:
You don’t need to assign the result somewhere in order to use this new expression syntax, and in fact it combines beautifully with [SE-0255](https://github.com/apple/swift-evolution/blob/master/proposals/0255-omit-return.md) from Swift 5.1 that allows us to omit the `return` keyword in single expression functions that return a value.

So, because both `if` and `switch` can now both be used as expressions, we can write a function like this one without using `return` in all four possible cases:
*/
func rating(for score: Int) -> String {
    switch score {
    case ...300: "Fail"
    case 301...500: "Pass"
    case 501...800: "Merit"
    default: "Distinction"
    }
}
    
print(rating(for: score))
/*:
You might be thinking this feature makes `if` work more like the ternary conditional operator, and you’d be at least partly right. For example, we could have written our simple `if` condition from earlier like this:
*/
let ternaryResult = score > 500 ? "Pass" : "Fail"
print(ternaryResult)
/*:
However, the two are not identical, and there is one place in particular that might catch you out – you can see it in this code:
*/
let customerRating = 4
let bonusMultiplier1 = customerRating > 3 ? 1.5 : 1
let bonusMultiplier2 = if customerRating > 3 { 1.5 } else { 1.0 }
/*:
Both those calculations produce a `Double` with the value of 1.5, but pay attention to the alternative value for each of them: for the ternary option I’ve written 1, and for the `if` expression I’ve written 1.0.

This is intentional: when using the ternary Swift checks the types of both values at the same time and so automatically considers 1 to be 1.0, whereas with the `if` expression the two options are type checked independently: if we use 1.5 for one case and 1 for the other then we’ll be sending back a `Double` and an `Int`, which isn’t allowed.

&nbsp;

[< Previous](@previous)           [Home](Introduction)           [Next >](@next)
*/