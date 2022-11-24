defmodule Pleroma.Web.ActivityPub.MRF.DisallowOutgoingPublicPolicy do
  @moduledoc "MRF policy which drops as:Public from outgoing activities"
  @behaviour Pleroma.Web.ActivityPub.MRF.Policy

  require Logger

  defp local?(actor) do
    String.starts_with?(actor, Pleroma.Web.Endpoint.url())
  end

  defp remove_public(recipients) do
    Enum.filter(recipients, fn value ->
      value not in ["Public", "as:Public", "https://www.w3.org/ns/activitystreams#Public"]
    end)
  end

  defp maybe_update_nested_object_addressing(message, to, cc) do
    if is_map(Map.get(message, "object")) do
      object =
        Map.get(message, "object")
        |> Map.put("to", to)
        |> Map.put("cc", cc)

      Map.put(message, "object", object)
    else
      message
    end
  end

  @impl true
  def filter(
        %{
          "to" => to,
          "cc" => cc,
          "actor" => actor
        } = message
      ) do
    if local?(actor) do
      to = to |> remove_public()
      cc = cc |> remove_public()

      message =
        message
        |> Map.put("to", to)
        |> Map.put("cc", cc)
        |> maybe_update_nested_object_addressing(to, cc)
    end

    {:ok, message}
  end

  @impl true
  def filter(message) do
    {:ok, message}
  end

  @impl true
  def describe, do: {:ok, %{}}

  @impl true
  def config_description do
    %{
      key: :mrf_remove_public,
      related_policy: "Pleroma.Web.ActivityPub.MRF.RemovePublicPolicy",
      label: "MRF Remove Public Policy",
      description: "Drop as:Public addressing from outgoing activities"
    }
  end
end
