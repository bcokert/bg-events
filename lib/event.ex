defmodule Event do
  @enforce_keys [:name, :date, :creator]
  defstruct [:name, :date, :creator, :description, :link, participants: []]

  @type t :: %Event{
    name: String.t(),
    date: DateTime.t(),
    creator: Nostrum.Snowflake.t(),
    participants: [Nostrum.Snowflake.t()],
    link: String.t(),
    description: String.t()
  }

  require Logger
  alias Nostrum.Api

  def run_command(command) do
    channel = case Nostrum.Cache.ChannelCache.get(command.discord_msg.channel_id) do
      {:ok, channel} ->
        channel
      {:error, reason} ->
        Logger.warn "Did not find #{command.discord_msg.channel_id} in channel cache: #{reason}"
    end
    Logger.info "Running #{command} in #{channel.name}"
    case command do
      %Command{command: "help", args: _, discord_msg: discord_msg} ->
        help(discord_msg)
      %Command{command: "soon", args: _, discord_msg: discord_msg} ->
        soon(discord_msg)
      %Command{command: "me", args: _, discord_msg: discord_msg} ->
        me(discord_msg)
      %Command{command: "add", args: [name, date | _], discord_msg: discord_msg} ->
        add(discord_msg, name, date)
      %Command{command: "remove", args: [name | _], discord_msg: discord_msg} ->
        remove(discord_msg, name)
      %Command{command: "register", args: [name | users], discord_msg: discord_msg} ->
        register(discord_msg, name, users)
      %Command{command: "unregister", args: [name | users], discord_msg: discord_msg} ->
        unregister(discord_msg, name, users)
      _ ->
        Api.create_message(command.discord_msg.channel_id, "Unknown command: #{command}")
    end
  end

  defp help(discord_msg) do
    Api.create_message(discord_msg.channel_id, "I'll dm you")

    case Api.create_dm(discord_msg.author.id) do
      {:ok, channel} ->
        Api.create_message(channel.id, String.trim("""
        Available commands:
        - help
            Shows this help text.
            eg: '!events help'

        - soon
            Shows events coming in the next 7 days.
            This is the default when just using '!events' without a command.
            eg: '!events soon'
            eg: '!events'

        - me
            Shows all events that you are registered for
            eg: '!events me'

        - add <name> <date>
            Creates an event with the given name and date.
            Will ask for more information.
            Events will be automatically added to the calendar.
            Only users with the ''Event Creator' role can create events.
            eg: '!events "BG Super Tourney" "2019-08-22 17:00:00 PDT"'

        - remove <name>
            Deletes an event with the given name.
            Only the creator or admin can delete an event.
            eg: '!events delete "BG Super Tourney"'

        - register <name> <@discordUser1> <@discordUser2> <...>
            Registers the given discord users to the given event.
            Only creators and admins can do this.
            Registering a user will make them receive event reminders.
            Use discords autocomplete/user selector to ensure the name is right.
            eg: '!events register "BG Super Tourney" @PhysicsNoob#2664 @AsheN🌯#0002'

        - unregister <name> <@discordUser1> <@discordUser2> <...>
            Unregisters the given discord users to the given event.
            Creators and admins, can do this, and users can also unregister themselves.
            Registering a user will make them receive event reminders.
            Use discords autocomplete/user selector to ensure the name is right.
            eg: '!events register "BG Super Tourney" @PhysicsNoob#2664 @AsheN🌯#0002'
        """))
      {:error, reason} ->
        Logger.warn "Failed to create dm in help command: #{reason}"
    end
  end

  defp soon(discord_msg) do
    case Event.Persister.get_all() do
      :error ->
        Api.create_message(discord_msg.channel_id, "Oops! Something went wrong fetching upcoming events. Please tell PhysicsNoob")
      [] -> 
        Api.create_message(discord_msg.channel_id, "No Events are Upcoming")
      events ->
        eventLines = Enum.map(events, fn e -> soon_format_event(e) end)
        Api.create_message(discord_msg.channel_id, """
        Upcoming Events:
          #{Enum.join(eventLines, "\n  ")}
        """)
    end
  end

  defp soon_format_event(event) do
    creator = case Nostrum.Cache.UserCache.get(event.creator) do
      {:ok, %Nostrum.Struct.User{username: name, discriminator: disc}} ->
        name <> "#" <> disc
      {:error, reason} ->
        Logger.warn("Failed to get creator from cache in 'soon': #{reason}")
        "@#{event.creator}"
    end

    participants = Enum.map(event.participants, fn p -> 
      case Nostrum.Cache.UserCache.get(p) do
        {:ok, %Nostrum.Struct.User{username: name, discriminator: disc}} ->
          name <> "#" <> disc
        {:error, reason} ->
          Logger.warn("Failed to get participant from cache in 'soon': #{reason}")
          "@#{p}"
      end
    end)

    description = case event.description do
      nil ->
        ""
      _ ->
        "\n`#{event.description}`"
    end

    link = case event.link do
      nil ->
        ""
      _ ->
        "\n#{event.link}"
    end

    """
    #{event.name}
        By #{creator}
        #{DateTime.to_date(event.date)} at #{event.date.hour}:#{event.date.minute} (#{event.date.time_zone})#{link}#{description}
        Participants (#{length(participants)}):
          #{Enum.join(participants, "\n  ")}
    """
  end

  defp me(discord_msg) do
    Logger.info "Running unimplemented me command"
    Api.create_message(discord_msg.channel_id, "WIP")
  end

  defp add(discord_msg, name, date_str) do
    case DateTime.from_iso8601(date_str) do
      {:ok, date, _} ->
        case Event.Persister.create(%Event{name: name, date: date, creator: discord_msg.author.id}) do
          :error ->
            Api.create_message(discord_msg.channel_id, "Oops! Something went wrong creating that event. Please tell PhysicsNoob")
          event ->
            creator = case Nostrum.Cache.UserCache.get(discord_msg.author.id) do
              {:ok, %Nostrum.Struct.User{username: name, discriminator: disc}} ->
                name <> "#" <> disc
              {:error, reason} ->
                Logger.warn("Failed to get creator from cache in 'add': #{reason}")
                "@#{event.creator}"
            end
            Api.create_message(discord_msg.channel_id, """
            Event Created!
              #{event.name} by #{creator} on #{DateTime.to_date(event.date)} at #{event.date.hour}:#{event.date.minute} (#{event.date.time_zone})
            """)
        end
      {:error, _} ->
        Api.create_message(discord_msg.channel_id, "Illegal input date: #{date_str}. Compare it to '2021-01-19T16:30:00-08'")
    end
  end

  defp remove(discord_msg, name) do
    Logger.info "Running unimplemented remove(#{name}) command"
    Api.create_message(discord_msg.channel_id, "WIP")
  end

  defp register(discord_msg, name, users) do
    Logger.info "Running unimplemented register(#{name}, [#{Enum.join(users, ", ")}]) command"
    Api.create_message(discord_msg.channel_id, "WIP")
  end

  defp unregister(discord_msg, name, users) do
    Logger.info "Running unimplemented unregister(#{name}, [#{Enum.join(users, ", ")}]) command"
    Api.create_message(discord_msg.channel_id, "WIP")
  end
end
