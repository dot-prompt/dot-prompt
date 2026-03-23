defmodule DotPrompt.Compiler.ResponseCollector do
  @moduledoc """
  Collects response blocks from AST and derives schema.
  """

  @doc """
  Collects all response blocks from the AST body.
  Returns a list of {content, line} tuples.
  """
  def collect_response_blocks(body) do
    Enum.filter_map(
      body,
      fn
        {:response, _, _} -> true
        _ -> false
      end,
      fn
        {:response, content, line} -> {content, line}
      end
    )
  end

  @doc """
  Derives a schema map from a JSON string.
  """
  def derive_schema(json_string) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, json} -> derive_schema_from_map(json)
      {:error, _} -> %{}
    end
  end

  defp derive_schema_from_map(json) when is_map(json) do
    Enum.into(json, %{}, fn {k, v} ->
      {k, schema_for_value(v)}
    end)
  end

  defp schema_for_value(v) when is_binary(v), do: %{type: "string", required: true}
  defp schema_for_value(v) when is_integer(v), do: %{type: "number", required: true}
  defp schema_for_value(v) when is_float(v), do: %{type: "number", required: true}
  defp schema_for_value(v) when is_boolean(v), do: %{type: "boolean", required: true}
  defp schema_for_value(v) when is_nil(v), do: %{type: "null", required: false}

  defp schema_for_value(v) when is_list(v) do
    if Enum.empty?(v) do
      %{type: "array", required: true, items: %{}}
    else
      first_item = Enum.at(v, 0)
      %{type: "array", required: true, items: schema_for_value(first_item)}
    end
  end

  defp schema_for_value(v) when is_map(v) do
    %{type: "object", required: true, fields: derive_schema_from_map(v)}
  end

  @doc """
  Compares multiple response schemas.
  Returns :compatible if same fields (different values),
  :incompatible if different fields or types,
  :identical if exactly the same.
  """
  def compare_schemas([]), do: :identical
  def compare_schemas([_]), do: :identical

  def compare_schemas(schemas) do
    schemas_list = Enum.map(schemas, &sort_schema_map/1)

    [first | rest] = schemas_list

    if Enum.all?(rest, fn s -> s == first end) do
      :identical
    else
      compare_schemas_rec(first, rest)
    end
  end

  defp compare_schemas_rec(first, []) do
    :compatible
  end

  defp compare_schemas_rec(first, [next | rest]) do
    case schemas_compatible?(first, next) do
      true -> compare_schemas_rec(first, rest)
      false -> :incompatible
    end
  end

  defp schemas_compatible?(schema1, schema2) do
    keys1 = Map.keys(schema1) |> MapSet.new()
    keys2 = Map.keys(schema2) |> MapSet.new()

    if keys1 == keys2 do
      Enum.all?(Map.keys(schema1), fn k ->
        type1 = schema1[k][:type]
        type2 = schema2[k][:type]
        type1 == type2
      end)
    else
      false
    end
  end

  defp sort_schema_map(schema) do
    schema
    |> Enum.into([], fn {k, v} -> {k, v} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{}, fn {k, v} -> {k, sort_schema_value(v)} end)
  end

  defp sort_schema_value(%{type: "object", fields: fields}) do
    %{type: "object", fields: sort_schema_map(fields), required: true}
  end

  defp sort_schema_value(%{type: "array", items: items}) do
    %{type: "array", items: sort_schema_value(items), required: true}
  end

  defp sort_schema_value(v), do: v
end
