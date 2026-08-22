defmodule Incld do
  @moduledoc """
  Elixir client for the incld API.
  """

  @default_base_url "https://api.incld.dev/v1"

  @doc """
  Creates a Req client for the incld API.

  Pass `:base_url` to target a local API or proxy in development.
  """
  def client(api_key, opts \\ []) do
    Req.new(
      base_url: Keyword.get(opts, :base_url, @default_base_url),
      auth: {:bearer, api_key}
    )
  end
end
