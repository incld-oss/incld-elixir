defmodule Incld.Actions do
  @moduledoc "Functions for defining and inspecting INCLD actions."

  alias Incld.Request

  def define(client, payload), do: Request.post_data(client, "/actions", payload, [200, 201])
  def list(client, params \\ %{}), do: Request.get_page(client, "/actions", params)
  def get(client, identifier), do: Request.get_data(client, "/actions/#{identifier}")
end
