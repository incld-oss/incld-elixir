defmodule Incld.Audit do
  @moduledoc "Server-side helpers for querying, creating, and tombstoning incld audit events."

  alias Incld.Request

  def list(client, params \\ %{}), do: Request.get_page(client, "/audit-events", params)
  def get(client, id), do: Request.get_data(client, "/audit-events/#{id}")

  def create(client, attrs, opts \\ []) when is_map(attrs),
    do: Request.post_data(client, "/audit-events", attrs, [201], opts)

  @doc "Erases PII-bearing event fields and appends a tombstone record. Trusted servers only."
  def tombstone(client, id, attrs, opts \\ []) when is_map(attrs),
    do: Request.post_data(client, "/audit-events/#{id}/tombstone", attrs, [200], opts)
end
