defmodule Incld do
  @moduledoc """
  Elixir client for the incld API.

  Tenant-bound server calls must include a stable `external_organization_id`.
  """

  @default_base_url "https://api.incld.dev/v1"

  @doc """
  Creates a Req client for the incld API.

  Pass `:base_url` to target a local API or proxy in development. Pass
  `:organization_id` and optionally `:user_id` to constrain every request at the
  API authorization boundary.
  """
  def client(api_key, opts \\ []) do
    organization_id = Keyword.get(opts, :organization_id)
    user_id = Keyword.get(opts, :user_id)

    validate_scope!(organization_id, user_id)

    headers =
      []
      |> maybe_header("incld-organization-id", organization_id)
      |> maybe_header("incld-user-id", user_id)

    Req.new(
      base_url: Keyword.get(opts, :base_url, @default_base_url),
      auth: {:bearer, api_key},
      headers: headers
    )
  end

  defp maybe_header(headers, _name, nil), do: headers
  defp maybe_header(headers, name, value), do: [{name, value} | headers]

  defp validate_scope!(organization_id, user_id) do
    if organization_id != nil and
         (not is_binary(organization_id) or String.trim(organization_id) == "") do
      raise ArgumentError, ":organization_id must be a non-empty string"
    end

    if user_id != nil and (not is_binary(user_id) or String.trim(user_id) == "") do
      raise ArgumentError, ":user_id must be a non-empty string"
    end

    if user_id != nil and organization_id == nil do
      raise ArgumentError, ":user_id requires :organization_id"
    end
  end
end
