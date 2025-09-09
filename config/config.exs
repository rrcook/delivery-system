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

import Config

config :server,
  ecto_repos: [Prodigy.Core.Data.Repo],
  auth_timeout: 60 * 1000

config :server, Prodigy.Server.Scheduler,
  jobs: [
    expunge_job: [
      schedule: "@daily",
      task: {Prodigy.Server.Service.Messaging, :expunge, []}
    ]
  ]

config :recipeutil,
  use_emu2: "false",
  cook_location: "/Users/rrc/recipe",
  dosbox_location: "/Applications/DOSBox Staging.app/Contents/MacOS/dosbox",
  news_feed: "https://memeorandum.com/feed.xml",
  headline_news: "https://memeorandum.com/feed.xml",
  tech_news: "https://techmeme.com/feed.xml",
  entertainment_news: "https://wesmirch.com/feed.xml"

config :core, ecto_repos: [Prodigy.Core.Data.Repo], ecto_adapter: Ecto.Adapters.Postgres

config :logger, :console, format: "$time $metadata[$level] $message\n"
config :logger, level: :debug

import_config "#{Mix.env()}.exs"
