defmodule PartyTime.Games.Trivia.Question do
  @moduledoc """
  Defines the state for a Trvia question.
  """

  @type t :: %__MODULE__{
          prompt: String.t(),
          expected_answer: String.t(),
          value: non_neg_integer(),
          id: atom(),
          is_available: boolean()
        }

  @enforce_keys [:prompt, :expected_answer, :value, :id]
  defstruct [
    :prompt,
    :expected_answer,
    :value,
    :id,
    is_available: true
  ]
end
