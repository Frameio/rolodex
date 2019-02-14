# Rolodex

Rolodex generates documentation for your Phoenix API.

Simply annotate your Phoenix controller action functions with `@doc` metadata, and Rolodex will turn these descriptions into valid documentation for any platform.

Currently supports:
- [OpenAPI 3.0](https://swagger.io/specification/)

## Documentation

See [https://hexdocs.pm/rolodex](https://hexdocs.pm/rolodex)

## Installation

Rolodex is [available in Hex](https://hex.pm/packages/rolodex). Add it to your
deps in `mix.exs`:

```elixir
def deps do
  [
    {:rolodex, "~> 0.1.0"}
  ]
end
```
