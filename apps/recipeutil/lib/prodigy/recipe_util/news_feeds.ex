defmodule NewsFeeds do
  require Logger

  @number_of_feeds 10
  @margin 50
  @newline "\r\n "

  # Given a news feed XML in the memorandum family, send back an array
  # of tuples, each item is {headline, story}.
  # If we can't get the XML pulled down then return an empty array.
  def get_stories(news_feed, number_of_pages) do
    try do
      # The only part that I think will fail, the rest is just string manipulation

      req_body = HTTPoison.get!(news_feed).body
      IO.inspect("Got the body of #{news_feed}")

      number_of_catches = min(@number_of_feeds, number_of_pages)

      # For our purposes we're just going to chop up the descriptions from the feed
      # 10 should be enough to get 4 good ones
      {:ok, feed, _} = FeederEx.parse(req_body)
      IO.inspect("parse successful")
      article_summaries =
        Enum.take(feed.entries, 10)
        |> Enum.map(fn e -> e.summary end)

        # Take every string HTML and get the readable text out of it.
        # MOST of the time it's an author, then \n, then a headline and
        # next text separated by an emdash.
        # Sometimes there's not an emdash to split on so we filter out
        # lists that only have one element, then take 4 to pass back.
        Enum.map(article_summaries, fn s ->
          s
          |> Readability.article()
          |> Readability.readable_text()
          |> String.split("\n", parts: 2)
          |> Enum.at(1)
          # that's an emdash
          |> String.split("—", parts: 2)
          |> Enum.map(&String.trim/1)
        end)
        |> Enum.filter(fn l -> length(l) == 2 end)
        |> Enum.take(number_of_catches)
        |> Enum.map(fn article -> break_text_on_margin(article, @margin) end)
    rescue
      # If we can't get the request just return an empty list
      e ->
        IO.inspect("ruh roh")
        IO.inspect(e)
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        []
    end
  end

  defp break_text_on_margin([hl, body], margin) do
    # current_line = []
    words = String.split(body, ~r/\s+/u)  # Split the input text into words using regular expression
    {lines, current_line} = Enum.reduce(words, {[], []}, fn word, {lines, current_line} ->
      if length(current_line) == 0 do
        {lines, [word]}
      else
        line_length = String.length(Enum.join(current_line, " ")) + 1 + String.length(word)
        if line_length <= margin do
          {lines, current_line ++ [word]}
        else
          {lines ++ [Enum.join(current_line, " ")], [word]}
        end
      end
    end)

    if length(current_line) > 0 do
      [hl, Enum.join(lines ++ [Enum.join(current_line, " ")], @newline)]
    else
      [hl, Enum.join(lines, @newline)]
    end
  end
end
