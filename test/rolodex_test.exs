defmodule RolodexTest do
  use ExUnit.Case
  doctest Rolodex

  alias Rolodex.Route
  alias Rolodex.Mocks.{User, Comment, NotFound}

  describe "#generate_documentation/1" do
    # TODO
  end

  describe "#generate_routes/1" do
    # TODO
  end

  describe "#generate_schemas/1" do
    test "Generates multiple schemas from multiple response types" do
      routes = [
        %Route{
          responses: %{
            200 => User,
            404 => NotFound
          }
        }
      ]

      assert(
        Rolodex.generate_schemas(routes) == %{
          User => %{
            type: :object,
            desc: "A user record",
            properties: %{
              id: %{desc: "The id of the user", type: :uuid},
              email: %{desc: "The email of the user", type: :string},
              another_thing: %{desc: nil, type: :string},
              comment: %{
                type: :object,
                desc: "A comment record",
                ref: Comment,
                properties: %{
                  id: %{desc: "The comment id", type: :uuid},
                  text: %{desc: nil, type: :string}
                }
              },
              comments: %{
                type: :array,
                desc: nil,
                items: %{
                  type: :object,
                  desc: "A comment record",
                  ref: Comment,
                  properties: %{
                    id: %{desc: "The comment id", type: :uuid},
                    text: %{desc: nil, type: :string}
                  }
                }
              },
              comments_of_many_types: %{
                type: :array,
                desc: "List of text or comment",
                items: [
                  %{type: :string},
                  %{
                    type: :object,
                    desc: "A comment record",
                    ref: Comment,
                    properties: %{
                      id: %{desc: "The comment id", type: :uuid},
                      text: %{desc: nil, type: :string}
                    }
                  }
                ]
              }
            }
          },
          Comment => %{
            type: :object,
            desc: "A comment record",
            properties: %{
              id: %{desc: "The comment id", type: :uuid},
              text: %{desc: nil, type: :string}
            }
          },
          NotFound => %{
            type: :object,
            desc: "Not found response",
            properties: %{
              message: %{
                desc: nil,
                type: :string
              }
            }
          }
        }
      )
    end

    test "Does not duplicate schemas" do
      routes = [
        %Route{
          responses: %{
            200 => User,
            404 => NotFound
          }
        },
        %Route{
          responses: %{
            404 => NotFound
          }
        }
      ]

      assert(
        Rolodex.generate_schemas(routes) == %{
          User => %{
            type: :object,
            desc: "A user record",
            properties: %{
              id: %{desc: "The id of the user", type: :uuid},
              email: %{desc: "The email of the user", type: :string},
              another_thing: %{desc: nil, type: :string},
              comment: %{
                type: :object,
                desc: "A comment record",
                ref: Comment,
                properties: %{
                  id: %{desc: "The comment id", type: :uuid},
                  text: %{desc: nil, type: :string}
                }
              },
              comments: %{
                type: :array,
                desc: nil,
                items: %{
                  type: :object,
                  desc: "A comment record",
                  ref: Comment,
                  properties: %{
                    id: %{desc: "The comment id", type: :uuid},
                    text: %{desc: nil, type: :string}
                  }
                }
              },
              comments_of_many_types: %{
                type: :array,
                desc: "List of text or comment",
                items: [
                  %{type: :string},
                  %{
                    type: :object,
                    desc: "A comment record",
                    ref: Comment,
                    properties: %{
                      id: %{desc: "The comment id", type: :uuid},
                      text: %{desc: nil, type: :string}
                    }
                  }
                ]
              }
            }
          },
          Comment => %{
            type: :object,
            desc: "A comment record",
            properties: %{
              id: %{desc: "The comment id", type: :uuid},
              text: %{desc: nil, type: :string}
            }
          },
          NotFound => %{
            type: :object,
            desc: "Not found response",
            properties: %{
              message: %{
                desc: nil,
                type: :string
              }
            }
          }
        }
      )
    end

    test "Handles non-generated schemas" do
      routes = [
        %Route{
          responses: %{
            200 => User,
            201 => :ok,
            203 => "moved permanently",
            123 => %{"hello" => "world"},
            404 => NotFound
          }
        }
      ]

      assert(
        Rolodex.generate_schemas(routes) == %{
          User => %{
            type: :object,
            desc: "A user record",
            properties: %{
              id: %{desc: "The id of the user", type: :uuid},
              email: %{desc: "The email of the user", type: :string},
              another_thing: %{desc: nil, type: :string},
              comment: %{
                type: :object,
                desc: "A comment record",
                ref: Comment,
                properties: %{
                  id: %{desc: "The comment id", type: :uuid},
                  text: %{desc: nil, type: :string}
                }
              },
              comments: %{
                type: :array,
                desc: nil,
                items: %{
                  type: :object,
                  desc: "A comment record",
                  ref: Comment,
                  properties: %{
                    id: %{desc: "The comment id", type: :uuid},
                    text: %{desc: nil, type: :string}
                  }
                }
              },
              comments_of_many_types: %{
                type: :array,
                desc: "List of text or comment",
                items: [
                  %{type: :string},
                  %{
                    type: :object,
                    desc: "A comment record",
                    ref: Comment,
                    properties: %{
                      id: %{desc: "The comment id", type: :uuid},
                      text: %{desc: nil, type: :string}
                    }
                  }
                ]
              }
            }
          },
          Comment => %{
            type: :object,
            desc: "A comment record",
            properties: %{
              id: %{desc: "The comment id", type: :uuid},
              text: %{desc: nil, type: :string}
            }
          },
          NotFound => %{
            type: :object,
            desc: "Not found response",
            properties: %{
              message: %{
                desc: nil,
                type: :string
              }
            }
          }
        }
      )
    end
  end

  describe "#write/2" do
    # TODO
  end
end
