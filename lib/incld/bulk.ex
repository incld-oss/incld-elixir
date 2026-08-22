defmodule Incld.Bulk do
  @moduledoc "Server-side helpers for the incld Bulk API."

  alias Incld.Request

  def list(client, params \\ %{}),
    do: Request.get_page(client, "/bulk-operations", normalize_query(params))

  def get(client, id), do: Request.get_data(client, "/bulk-operations/#{id}")

  def create(client, attrs, opts \\ []) when is_map(attrs) do
    attrs =
      attrs
      |> rename(:chunk_size, "chunk_size")
      |> rename(:action, "action")
      |> rename(:items, "items")
      |> rename(:metadata, "metadata")

    Request.post_data(client, "/bulk-operations", attrs, [201], opts)
  end

  def chunks(client, id), do: Request.get_page(client, "/bulk-operations/#{id}/chunks")
  def events(client, id), do: Request.get_page(client, "/bulk-operations/#{id}/events")

  def cancel(client, id, opts \\ []) do
    payload = %{
      "actor_id" => Keyword.get(opts, :actor_id),
      "reason" => Keyword.get(opts, :reason)
    }

    Request.post_data(client, "/bulk-operations/#{id}/cancel", payload)
  end

  defp normalize_query(params) when is_list(params), do: params |> Map.new() |> normalize_query()

  defp normalize_query(params) when is_map(params) do
    params
    |> rename(:status, "status")
    |> rename(:action, "action")
    |> rename(:limit, "limit")
    |> rename(:starting_after, "cursor")
  end

  defp rename(map, atom_key, string_key) do
    case Map.pop(map, atom_key) do
      {nil, map} -> map
      {value, map} -> Map.put(map, string_key, value)
    end
  end
end
