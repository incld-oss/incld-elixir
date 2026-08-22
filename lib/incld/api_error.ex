defmodule Incld.APIError do
  @moduledoc "A structured error returned by the incld API."

  defexception [:status, :code, :message, :fields, :request_id]

  @impl true
  def message(error), do: "incld API error #{error.status} (#{error.code}): #{error.message}"
end
