defmodule Incld.Schedules do
  @moduledoc """
  Functions for interacting with incld Schedules.
  """

  alias Incld.Request

  def list(client, params \\ %{}),
    do: Request.get_page(client, "/schedules", normalize_cursor(params))

  def get(client, schedule_id), do: Request.get_data(client, "/schedules/#{schedule_id}")

  def create(client, payload, opts \\ []),
    do: Request.post_data(client, "/schedules", payload, [200, 201], opts)

  def update(client, schedule_id, payload),
    do: Request.patch_data(client, "/schedules/#{schedule_id}", payload)

  def delete(client, schedule_id), do: Request.delete(client, "/schedules/#{schedule_id}")

  def pause(client, schedule_id),
    do: Request.post_data(client, "/schedules/#{schedule_id}/pause", %{})

  def resume(client, schedule_id),
    do: Request.post_data(client, "/schedules/#{schedule_id}/resume", %{})

  def list_runs(client, schedule_id, params \\ %{}),
    do: Request.get_page(client, "/schedules/#{schedule_id}/runs", normalize_cursor(params))

  def events(client, schedule_id, params \\ %{}),
    do: Request.get_page(client, "/schedules/#{schedule_id}/events", normalize_cursor(params))

  def preview(client, recurrence, opts \\ []) do
    payload = %{
      recurrence: recurrence,
      count: Keyword.get(opts, :count, 3),
      from: Keyword.get(opts, :from)
    }

    Request.post_data(client, "/schedules/preview", payload)
  end

  defp normalize_cursor(params) when is_list(params),
    do: params |> Map.new() |> normalize_cursor()

  defp normalize_cursor(params) when is_map(params) do
    case Map.pop(params, :starting_after) do
      {nil, params} -> params
      {value, params} -> Map.put(params, :cursor, value)
    end
  end
end
