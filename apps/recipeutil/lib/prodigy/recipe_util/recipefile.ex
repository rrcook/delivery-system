defmodule RecipeUtil.File do
  require Ecto.Query
  import Ecto.Changeset

  alias Prodigy.Core.Data.{Object, Repo}

  # from reading the manual
  ## These two look good but don't clear the "screen"
  @headerx <<0xA1, 0xCA, 0xC1, 0xA3>>
  @headerx2 <<0xA1, 0xC8, 0xC0, 0xA3>>

  @header <<0xA1, 0xC8, 0xC0, 0xA3>>
  ## 0b11 001 01 0  0b11001010 0xca     0x6a
  ## 0b01 000 00 1  0b01000001 0x41

  # from plucking from the big buffer
  # @header <<0xA1, 0xC8, 0xC0, 0xC0>>

  @header2 <<0xA1, 0xC8, 0xC0, 0xC0, 0xD2, 0xA3, 0xC4, 0xC0, 0xD2, 0xC0, 0xBE, 0xC0, 0xC8, 0xB3, 0xC2,
  0xC6, 0xC2, 0xDE, 0xF8, 0xF1, 0xA2, 0xF0, 0xC0, 0xC0, 0xC1, 0xEA, 0xB8, 0xC0, 0xC0, 0xD8,
  0xDB, 0xF9, 0xE8, 0xA4, 0xC2, 0xC4, 0xDF, 0xBE, 0xD0,
  0x0F>>

  @number_of_pages 4

  @subst_map %{
    "Body" =>
        "This is line 1 big that has been changed" <>
        <<0x0D, 0x0A, 0x20>> <>
        "This is line 2" <>
        <<0x0D, 0x0A, 0x20>> <>
        "This is a longer line 3",
    "HL" =>
    @header <>
       "      This is a headline for page 2 of 3",
    "NextHL" => "Go to next page"
  }

  @subst_map2 %{
    "Body" =>
      "This is line 1 small that has been changed" <>
        <<0x0D, 0x0A, 0x20>> <>
        "This is line 2" <>
        <<0x0D, 0x0A, 0x20>> <>
        "This is a longer line 3",
    "HL" => "This is a headline",
    "NextHL" => "Go to next page"
  }

  def run(%{:page_setup => true} = args) do
    source = Map.get(args, :source)
    dest = Map.get(args, :dest)

    with {:ok, data} <- File.read(source) do
      data_with_page_info = page_setup(data, 1, 2)

      if dest do
        File.write!(dest, data_with_page_info)
      else
        IO.inspect(data_with_page_info)
      end
    end
  end

  def run(%{:news_setup => true} = args) do
    source = Map.get(args, :source)
    # dest = Map.get(args, :dest)
    dest = "NH00A000B  "

    IO.inspect("in news setup")

    recipe_object =
      if String.printable?(source) do
        Object
        |> Ecto.Query.where([o], o.name == ^source)
        |> Ecto.Query.where([o], o.type == 200)
        |> Ecto.Query.select([o], [o.name, o.type, o.contents])
        |> Repo.one()
      else
        nil
      end

    if recipe_object != nil do
      # get file contents we want
      [_name, _type, contents] = recipe_object
      # make the file name we'll write to
      {base, extension} = String.split_at(source, 8)
      filename = "#{base}.#{extension}"

      # future magic here, make a news headline map
      news_feed = Application.fetch_env!(:recipeutil, :tech_news)
      # news_feed = "https://memeorandum.com/feed.xml"
      news_stories = NewsFeeds.get_stories(news_feed, @number_of_pages)
      IO.inspect("got news stories, #{news_stories}")

      num_items = length(news_stories)
      with_indices = Enum.zip(1..num_items, news_stories)

      Enum.map(with_indices, fn item ->
        {index, [hl, body]} = item

        page_map = %{
          "Body" =>
              body,
          "HL" =>
          @header <>
             hl,
          "NextHL" => "Go to next page"
        }
        create_one_page(contents, page_map, filename, dest, index, num_items )
      end)

    end
  end

  def run(%{} = args) do
    source = Map.get(args, :source)
    dest = Map.get(args, :dest)

    with {:ok, data} <- File.read(source) do
      {:ok, recipe, _rest} = RecipeType.parse(data, %{})
      # IO.inspect(recipe_type)
      recipe_bytes = RecipeType.generate(recipe)

      if dest do
        File.write!(dest, recipe_bytes)
      else
        IO.inspect(recipe)
      end
    end
  end

  defp create_one_page(
         recipe_contents,
         subst_map,
         filename,
         destination,
         current_page,
         total_pages
       ) do
    # Turn into a recipe struct with new headline info in it
    {:ok, recipe, _rest} = RecipeType.parse(recipe_contents, subst_map)
    # new recipe data
    recipe_bytes = RecipeType.generate(recipe)

    # write to file so we can run cook on it
    cook_location = Application.fetch_env!(:recipeutil, :cook_location)
    rf_location = Path.join([cook_location, filename])
    File.write!(rf_location, recipe_bytes)
    # for debugging
    File.write!(rf_location <> ".#{current_page}", recipe_bytes)

    use_emu2 = false

    body_filename = if use_emu2 do
      # run cook on the file
      emu2_command = Path.join([cook_location, "emu2"])
      cook_command = Path.join([cook_location, "COOK.EXE"])
      # run_cook_command = "EMU2_DRIVE_C=#{cook_location} #{emu2_command} COOK.EXE /INH00A000.BDY /R6 #{filename}"
      System.cmd(emu2_command, [cook_command, "/INH00A000.BDY", "/R6", filename],
        env: [{"EMU2_DRIVE_C", cook_location}]
      )
      Path.join(cook_location, "nh00a000.bdy")
    else
      dosbox_location = Application.fetch_env!(:recipeutil, :dosbox_location)
      # cook_location = Application.fetch_env!(:recipeutil, cook_location)
      conf_location = Path.join([cook_location, "cook.conf"])

      System.cmd(dosbox_location, ["-conf", conf_location, "-exit"],
        env: [{"SDL_VIDEODRIVER", "dummy"}]
      )

      #debug, copy the file
      bdy_location = Path.join(cook_location, "nh00a000.bdy")
      bdy_index_location = Path.join(cook_location, "nh00a000.bdy.#{current_page}")
      System.cmd("cp", ["-p", bdy_location, bdy_index_location])

      # read the resulting files back in
      Path.join(cook_location, "NH00A000.BDY")
    end



    body_contents =
      File.read!(body_filename)
      |> page_setup(current_page, total_pages)

    # Read the record from the database
    body_object =
      if String.printable?(destination) do
        Object
        |> Ecto.Query.where([o], o.name == ^destination)
        |> Ecto.Query.where([o], o.sequence == ^current_page)
        |> Repo.one()
      else
        nil
      end

    IO.inspect(body_contents)

    if body_object != nil do
      IO.puts("Doing an update")

      Ecto.Changeset.change(body_object, %{contents: body_contents})
      |> Repo.update()
    else
      IO.puts("Doing an insert")

      Repo.insert(%Object{
        name: destination,
        sequence: current_page,
        type: 8,
        version: 1,
        contents: body_contents
      })
    end
  end

  defp page_setup(buffer, page_number, total_pages) do
    <<
      buf1::binary-size(9),
      _extension1,
      _extension2,
      _orig_page_number,
      buf2::binary-size(3),
      orig_stage_flags,
      _orig_total_pages,
      rest::binary
    >> = buffer

    # the headline names in the object have the extension truncated to one letter
    # 8.3 -> 8.1 and two spaces
    <<
      buf1::binary-size(9),
      0x20,
      0x20,
      page_number,
      buf2::binary-size(3),
      orig_stage_flags,
      total_pages,
      rest::binary
    >>
  end

end
