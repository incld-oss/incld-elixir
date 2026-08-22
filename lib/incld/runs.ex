defmodule Incld.Runs do
  @moduledoc "Functions for listing incld execution runs."

  alias Incld.Request

  def list(client, params \\ %{}), do: Request.get_page(client, "/runs", normalize_params(params))

  def get(client, run_id), do: Request.get_data(client, "/runs/#{run_id}")

  defp normalize_params(params) when is_map(params) do
    params
    |> rename(:starting_after, :cursor)
    |> rename("starting_after", "cursor")
  end

  defp normalize_params(params), do: params

  defp rename(params, from, to) do
    case Map.pop(params, from) do
      {nil, params} -> params
      {value, params} -> Map.put(params, to, value)
    end
  end
end
