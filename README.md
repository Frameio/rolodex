# Rolodex

[![hex.pm version](https://img.shields.io/hexpm/v/rolodex.svg)](https://hex.pm/packages/rolodex) [![CircleCI](https://circleci.com/gh/Frameio/rolodex.svg?style=svg)](https://circleci.com/gh/Frameio/rolodex)

Rolodex generates documentation for your Phoenix API.

Simply annotate your Phoenix controller action functions with `@doc` metadata, and Rolodex will turn these descriptions into valid documentation for any platform.

Currently supports:
- [OpenAPI 3.0](https://swagger.io/specification/)

## Disclaimer

Rolodex is currently under active development! The API is a work in progress as we head towards v1.0.

## Documentation

See [https://hexdocs.pm/rolodex](https://hexdocs.pm/rolodex/Rolodex.html)

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
