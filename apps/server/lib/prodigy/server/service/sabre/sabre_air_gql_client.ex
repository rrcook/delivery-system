defmodule Prodigy.Server.Service.Sabre.SabreAirGqlClient do
  @moduledoc """
  Maps Sabre Air messages to internal client message format and vice versa.
  """

  @doc """
  Converts a Sabre Air date string (e.g., "JAN15") to a Date struct.
  """
  require Logger

  @url  "http://localhost:4000/api/graphql"

  @behaviour Prodigy.Server.Service.Sabre.SabreAirClient

  def handle_request(sabre_map) do
    # Implementation of request handling

    # A string will be posted to the GraphQL endpoint and a response received
    post_body = build_request(sabre_map)

    Logger.info("Sending GraphQL request: #{post_body}")
    url = Application.get_env(:server, :sabre_graphql_url, @url)

    response =
      Req.post(url,
        body: post_body,
        headers: %{"Content-Type" => "text/plain"}
      )

      Logger.info("Received GraphQL response: #{inspect(response)}")
    parse_response(response)

  end

  defp parse_response(response) do
    # Parse the GraphQL response body and extract flight information
    case response do
      {:ok, %Req.Response{status: 200, body: body}} ->
        try do
          body |> Map.get("data") |> Map.get("flights")
        rescue
          e ->
            IO.puts("Failed to parse GraphQL response body: #{inspect(e)}")
            []
        end
      {:ok, %Req.Response{status: status}} ->
        IO.puts("GraphQL request failed with status: #{status}")
        []

      {:error, reason} ->
        IO.puts("GraphQL request error: #{inspect(reason)}")
        []
    end
  end

  defp build_request(sabre_map) do
    # Build the GraphQL request body from the sabre_map

    fromDate_text = "fromDate: \"#{adjust_date(sabre_map.date)}\", "
    toDate_text = "toDate: \"#{adjust_date(sabre_map.date)}\", "
    origin_text = "origin: \"#{sabre_map.departure}\", "
    dest_text = "dest: \"#{sabre_map.arrival}\", "

    carrier_text = if Map.has_key?(sabre_map, :carrier) and sabre_map.carrier != nil do
      "carrier: \"#{sabre_map.carrier}\", "
    else
      ""
    end

    # If there's a flight number, use it directly else there should be a departure time to use
    f_or_d_text = if Map.has_key?(sabre_map, :flight_number) and sabre_map.flight_number != nil do
      "flightNumber: \"#{sabre_map.flight_number}\", "
    else
      "departureTime: \"#{sabre_map.time}\", "
    end

    query_text = """
    query {
      flights(
        #{fromDate_text}
        #{toDate_text}
        #{origin_text}
        #{dest_text}
        #{carrier_text}
        #{f_or_d_text}
        limit: 100) {
          id
          flightNumber
          date
          origin
          dest
          carrier
          arrivalTime
          departureTime
          airline {
            name
          }
      }
    }
    """
  end

  defp adjust_date(date_text) do
    date = Date.from_iso8601!(date_text)
    year_shift = 2013 - date.year
    Date.shift(date, year: year_shift) |> Date.to_string()
  end
end
