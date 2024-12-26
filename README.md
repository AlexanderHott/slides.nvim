# `slides.nvim`

Slides, but in Neovim.

# Usage

Run `:StartSlides` in a markdown file.

Use `n` and `p` to navigate slides, and `q` to quit.

To include executors for other languages, call the setup function with the language (js) matching the markdown codeblock.

```lua
-- lazy.nvim
{
    "AlexanderHott/slides.nvim",
    config = function()
        local slides = require("slides")
        -- make sure that the next arg can be a file name, e.g. `bun run file.ts`
        local bun_executor = slides.create_system_executor({ "bun", "run" })
        slides.setup({ executors = { js = bun_executor, ts = bun_executor } })
    end,
}
```

# Features

You can also use `X` to run code blocks

```lua
print("hi", 42)
```

# Even other languages

```js
function add(x, y) {
    return x + y
}

console.log(add(22, 20))
```

# Rust btw

```rs
fn main() {
    println!("hi from rust");
}
```
