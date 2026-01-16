defmodule Prodigy.Server.Service.Sabre.SabreAirClient do
  @moduledoc """
  Behaviour defining the interface for Sabre Air message handlers.

  Implementations of this behaviour are responsible for processing parsed
  Sabre Air requests and returning flight information.
  """

  @doc """
  Handles a Sabre Air request and returns flight results.

  ## Parameters

    * `request` - A map containing parsed Sabre Air request parameters including:
      * `:departure` - Origin airport code
      * `:arrival` - Destination airport code
      * `:date` - Flight date in ISO 8601 format
      * `:time` - Departure time (optional if flight_number provided)
      * `:carrier` - Airline carrier code (optional)
      * `:flight_number` - Specific flight number (optional)

  ## Returns

  A list of maps, where each map represents a flight with fields like
  `"flightNumber"`, `"origin"`, `"dest"`, `"departureTime"`, `"arrivalTime"`, etc.
  Returns an empty list if no flights are found or an error occurs.
  """
  @callback handle_request(map()) :: list(map())

end
