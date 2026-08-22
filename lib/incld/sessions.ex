defmodule Incld.Sessions do
  @moduledoc "Functions for creating scoped INCLD session tokens."

  alias Incld.Request

  def create(client, claims) when is_map(claims),
    do: Request.post_data(client, "/sessions", %{claims: claims})
end
