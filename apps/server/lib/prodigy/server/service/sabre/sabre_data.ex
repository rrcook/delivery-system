defmodule Prodigy.Server.Service.Sabre.SabreData do
  @moduledoc """
  Module for handling SD Airport related functionalities.
  """

  @doc """
  Sample function to demonstrate module functionality.
  """
#   def data_into_map(file) do
#     for line <- File.stream!(file, [], :line), into: %{} do
#       [faa_code, airport_name] = line |> String.split(";") |> Enum.map(&String.strip(&1))
#       {faa_code, airport_name}
#
#     end
#   end

  @data_into_map fn file ->
    for line <- File.stream!(file, [], :line), into: %{} do
      [faa_code, airport_name] = line |> String.split(";") |> Enum.map(&String.trim(&1))
      {faa_code, airport_name}

    end
  end

  @external_resource airports_file = Path.join([__DIR__, "us_airports.txt"])
  @external_resource airlines_file = Path.join([__DIR__, "airlines.txt"])

  @airports_map @data_into_map.(airports_file)
  @airlines_map @data_into_map.(airlines_file)

  def airports_map do
    @airports_map
  end

  def airlines_map do
    @airlines_map
  end
end
