# Copyright 2022, Phillip Heller
#
# This file is part of Prodigy Reloaded.
#
# Prodigy Reloaded is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# Prodigy Reloaded is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with Prodigy Reloaded. If not,
# see <https://www.gnu.org/licenses/>.

defmodule Prodigy.Server.Service.EaasySabre do
  @behaviour Prodigy.Server.Service
  @moduledoc """
  Handle Eaasy Sabre requests
  """

  require Logger

  alias Prodigy.Server.Protocol.Dia.Packet, as: DiaPacket
  alias Prodigy.Server.Protocol.Dia.Packet.{Fm0, Fm4, Fm64}
  alias Prodigy.Server.Context

  # send main menu in response to signon
  defp int_handle("/SIGNON" <> <<rest::binary>>) do
    Logger.info("received eaasy sabre signon:")

    <<
      # header len
      7,
      # unused?
      0,
      # map
      0x01,
      # main menu
      0x4700::16-big,
      0,
      0
    >>
  end

  defp int_handle("/M" <> <<rest::binary>>) do
    Logger.info("received eaasy sabre M:")

    <<
      # header len
      7,
      # unused?
      0,
      # map
      0x01,
      # main menu
      0x4700::16-big,
      0,
      0
    >>
  end

  # send reservation menu in response to that menu selection
  defp int_handle("2") do
    Logger.info("received eaasy sabre 2:")

    <<
      7,
      0,
      0x01,
      0x0D03::16-big,
      0,
      0
    >>
  end

  # send flight input form
  defp int_handle("1     ") do
    Logger.info("received eaasy sabre '1     ':")

    <<
      7,
      0,
      0x01,
      0x0200::16-big,
      0,
      0
    >>
  end

  # send some flight options
  defp int_handle("/AIR," <> <<rest::binary>>) do
    # split rest on , to get the input values
    Logger.info("received eaasy sabre /AIR:")

    <<
      7,
      0,
      0x01,
      # what page renders this data
      0x0900::16-big,
      # how many rows of data are coming
      9,
      0,
      0x24,
      0x27,
      0,
      9,
      "OCT 05 21"::binary,
      0x10,
      0x27,
      0,
      39,
      "AA 1261 DFW  620P LAX 1103P R  0 D10  8"::binary,
      0x11,
      0x27,
      0,
      39,
      "UA  456 DFW  700P LAX 1145P L  0 767  N"::binary,
      # -> selector in field 16
      0x75,
      0x27,
      0x00,
      7,
      "AA 1261"::binary,
      # -> selector in field 17
      0xD9,
      0x27,
      0x00,
      7,
      "UA  456"::binary,
      0xE2,
      0x27,
      0,
      7,
      "AA 1261"::binary,
      0x38,
      0x27,
      0,
      7,
      "UA  456"::binary,
      0x6A,
      0x27,
      0,
      22,
      "F  Y  B  M  H  Q  V  K"::binary,
      0x6B,
      0x27,
      0,
      13,
      "Y  B  M  H  Q"::binary
    >>
  end

  defp int_handle("/SIGNOFF", <<rest::binary>>) do
    Logger.info("received eaasy sabre /SIGNOFF:")

    <<
      0x0
    >>
  end

  defp int_handle(rest) do
    Logger.warning(
      "unhandled eaasy saabre request: #{inspect(rest, base: :hex, limit: :infinity)}"
    )

    <<0>>
  end

  def handle(%Fm0{dest: 0x063201, payload: payload} = request, %Context{} = context) do
    Logger.warning("es rx : #{inspect(payload, limit: :infinity)}")
    response_payload = int_handle(payload)
    Logger.warning("es tx : #{inspect(response_payload, limit: :infinity)}")

    response = %{
      request
      | concatenated: false,
        src: request.dest,
        dest: request.src,
        mode: %Fm0.Mode{response: true},
        fm4: nil,
        fm9: nil,
        fm64: nil,
        payload: response_payload
    }

    {:ok, context, DiaPacket.encode(response)}
  end
end
