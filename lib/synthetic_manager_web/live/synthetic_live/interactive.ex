defmodule SyntheticManagerWeb.SyntheticLive.Interactive do
  use SyntheticManagerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

end
