# ContainUI
ContainUI is a UI library for [LÖVE](https://love2d.org/). It is loosely based on html/css.

The aim of this library is to be extremely easy to get started with - And to make sure the more advanced features are optional and don't intrude on the experience of users who don't need them.

It's also just something I'm doing for fun :)

[Check out the Getting Started page.](https://github.com/gagehenderson/ContainUI/wiki/Getting-Started)

# Features
- Create layouts quickly and easily using the Container element.
- Text, image, text input, dropdowns, and button elements.
- Controller navigation support.
- Built in animation support.
- (Optionally) Use css-style classes to organize code and ensure a consistent visual style.

# Quick example
```Lua
local container = Container:new({
    dimensions = { width = "100%", height = "100%" },
    align_children = "center",
    justify_children = "center",
})
container:add_child(Text:new({
    text = "Hello, world!",
}))
```
![Result of quick example code.](https://raw.githubusercontent.com/gagehenderson/ContainUI/refs/heads/main/docs/images/quick-example.png)
