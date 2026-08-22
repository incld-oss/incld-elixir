defmodule Incld.Request do
  @moduledoc false

  def get_data(client, path, params \\ %{}) do
    case Req.get(client, url: path, params: params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, unwrap_data(body)}

      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        {:error, api_error(status, body, headers)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  def get_page(client, path, params \\ %{}) do
    case Req.get(client, url: path, params: params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, page(body)}

      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        {:error, api_error(status, body, headers)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  def get(client, path, params \\ %{}) do
    case Req.get(client, url: path, params: params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        {:error, api_error(status, body, headers)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  def post_data(client, path, payload, accepted \\ [200], opts \\ []) do
    case Req.post(client, url: path, json: payload, headers: idempotency_headers(opts)) do
      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        if status in accepted,
          do: {:ok, unwrap_data(body)},
          else: {:error, api_error(status, body, headers)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  def post(client, path, payload, accepted \\ [200], opts \\ []) do
    case Req.post(client, url: path, json: payload, headers: idempotency_headers(opts)) do
      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        if status in accepted,
          do: {:ok, body},
          else: {:error, api_error(status, body, headers)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  def patch_data(client, path, payload) do
    case Req.patch(client, url: path, json: payload) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, unwrap_data(body)}

      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        {:error, api_error(status, body, headers)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  def delete(client, path) do
    case Req.delete(client, url: path) do
      {:ok, %Req.Response{status: status, body: body}} when status in [200, 204] ->
        {:ok, unwrap_data(body)}

      {:ok, %Req.Response{status: status, body: body, headers: headers}} ->
        {:error, api_error(status, body, headers)}

      {:error, exception} ->
        {:error, exception}
    end
  end

  defp unwrap_data(%{"data" => data}), do: data
  defp unwrap_data(%{data: data}), do: data
  defp unwrap_data(body), do: body

  defp page(%{"data" => data, "meta" => meta}) do
    %{
      data: data,
      meta: %{
        has_more: Map.get(meta, "has_more", false),
        next_cursor: Map.get(meta, "next_cursor")
      }
    }
  end

  defp page(%{data: data, meta: meta}), do: %{data: data, meta: meta}

  defp api_error(status, body, headers) do
    error = Map.get(body, "error", Map.get(body, :error, %{}))
    error = if is_map(error), do: error, else: %{"message" => to_string(error)}

    %Incld.APIError{
      status: status,
      code: Map.get(error, "code", Map.get(error, :code, "unknown_error")),
      message: Map.get(error, "message", Map.get(error, :message, "Request failed")),
      fields: Map.get(error, "fields", Map.get(error, :fields)),
      request_id:
        Map.get(error, "request_id", Map.get(error, :request_id)) ||
          header(headers, "x-request-id")
    }
  end

  defp idempotency_headers(opts) do
    case Keyword.get(opts, :idempotency_key) do
      value when is_binary(value) and value != "" -> [{"idempotency-key", value}]
      _ -> []
    end
  end

  defp header(headers, name) do
    headers
    |> Enum.find_value(fn
      {^name, [value | _]} -> value
      {^name, value} when is_binary(value) -> value
      _ -> nil
    end)
  end
end
