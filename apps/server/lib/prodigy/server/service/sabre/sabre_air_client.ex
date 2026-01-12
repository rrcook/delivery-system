defmodule Prodigy.Server.Service.Sabre.SabreAirClient do
  @moduledoc """
  Client for handling Sabre Air messages
  """


  @callback handle_request(map()) :: list(map())

end
