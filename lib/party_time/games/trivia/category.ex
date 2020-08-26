defmodule PartyTime.Games.Trivia.Category do
  @moduledoc """
  Defines the state for a Trivia category.

  A category is a grouping of one or more
  questions that are related.
  """
  alias PartyTime.Games.Trivia.Question

  @type t :: %__MODULE__{
          name: String.t(),
          questions: list(Question.t())
        }

  @enforce_keys [:name]
  defstruct [
    :name,
    questions: []
  ]

  @doc """
  Add a new question to the category
  """
  @spec add_question(t(), String.t(), String.t(), non_neg_integer()) :: t()
  def add_question(category, prompt, expected_answer, value) do
    new_question = %Question{
      prompt: prompt,
      expected_answer: expected_answer,
      value: value,
      id: PartyTime.Games.Utils.make_id()
    }

    %{category | questions: [new_question | category.questions]}
  end
end
