defmodule Prodigy.Server.Service.Sabre.SabreAirMapper do
  @moduledoc """
  Maps between Sabre protocol and internal representations
  """

    @month_nums %{
    "JAN" => 1,
    "FEB" => 2,
    "MAR" => 3,
    "APR" => 4,
    "MAY" => 5,
    "JUN" => 6,
    "JUL" => 7,
    "AUG" => 8,
    "SEP" => 9,
    "OCT" => 10,
    "NOV" => 11,
    "DEC" => 12
  }

  @doc """
  Converts a date string with format "MMMDD" (e.g., "JAN15") to an Elixir Date.

  The month code should be three uppercase letters (JAN, FEB, etc.)
  followed by a two-digit day number.

  Uses the current year for the returned Date.
  """
  defp date_convert(date_string) do
    # Extract month code (first 3 chars) and day (last 2 chars)
    month_code = String.slice(date_string, 0, 3)
    day_string = String.slice(date_string, 3, 2)

    # Convert to integers
    month = month_code_to_number(month_code)
    day = String.to_integer(day_string)

    # Use current year
    year = Date.utc_today().year

    # Create and return the Date
    Date.new!(year, month, day)
  end

  @doc """
  Converts a time string with format "HHMMA" or "HMMA" (e.g., "130P", "1030A") to an Elixir Time.

  The string should contain 3 or 4 digits representing the time,
  followed by "A" for AM or "P" for PM.
  """
  defp time_convert(time_string) do
    # Extract AM/PM indicator (last character)
    am_pm = String.last(time_string)

    # Extract time digits (everything except last character)
    time_digits = String.slice(time_string, 0..-2//1)

    # Parse hour and minute based on length
    {hour, minute} =
      case String.length(time_digits) do
        3 ->
          # Format: HMM (e.g., "130" -> 1:30)
          hour = String.slice(time_digits, 0, 1) |> String.to_integer()
          minute = String.slice(time_digits, 1, 2) |> String.to_integer()
          {hour, minute}

        4 ->
          # Format: HHMM (e.g., "1030" -> 10:30)
          hour = String.slice(time_digits, 0, 2) |> String.to_integer()
          minute = String.slice(time_digits, 2, 2) |> String.to_integer()
          {hour, minute}
      end

    # Convert to 24-hour format
    hour_24 =
      case {hour, am_pm} do
        {12, "A"} -> 0   # 12 AM is midnight (00:xx)
        {12, "P"} -> 12  # 12 PM is noon (12:xx)
        {h, "P"} -> h + 12  # Other PM hours add 12
        {h, "A"} -> h    # Other AM hours stay the same
      end

    # Create and return the Time
    Time.new!(hour_24, minute, 0)
  end

  defp month_code_to_number(code), do: Map.get(@month_nums, code, "JAN")


  @doc """
  Takes in a Sabre message and converts it to a map
  """
  def to_map(sabre_message) do

    parts = String.split(sabre_message, ",")
    [message_type, departure, arrival, raw_date, raw_time, passengers | rest] = parts

    date = date_convert(raw_date) |> Date.to_string()
    time = time_convert(raw_time) |> Time.to_string()
    %{
      type: :airline,
      departure: departure,
      arrival: arrival,
      date: date,
      time: time,
      passengers: passengers
    }
  end

  def to_binary(_client_map) do
    # Placeholder mapping logic
    <<"TO BE IMPLEMENTED">>
  end
end
