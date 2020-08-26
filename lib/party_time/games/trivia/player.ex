defmodule PartyTime.Games.Trivia.Player do
  @moduledoc """
  Defines the shape of a player for the Trivia game.
  """

  @type t :: %__MODULE__{
          user_id: pos_integer(),
          display_name: String.t(),
          able_to_answer: boolean(),
          is_in_control: boolean(),
          score: integer()
        }

  @enforce_keys [:user_id, :display_name]
  defstruct [
    :user_id,
    :display_name,
    able_to_answer: true,
    is_in_control: false,
    score: 0
  ]
end
