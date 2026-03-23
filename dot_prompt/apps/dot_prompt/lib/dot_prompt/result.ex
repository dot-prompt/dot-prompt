defmodule DotPrompt.Result do
  @moduledoc """
  Result struct returned from compile/render operations.
  """

  defstruct prompt: nil, response_contract: nil, vary_selections: %{}, metadata: %{} 

  @type t :: %DotPrompt.Result{
          prompt: String.t() | nil,
          response_contract: map() | nil,
          vary_selections: map() | nil,
          metadata: map() | nil
        }
end
