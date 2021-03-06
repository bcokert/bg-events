defmodule FakeDiscordApi do
  def create_message(channel_id, msg) do
    send(self(), {channel_id, msg})
    {:ok, %Nostrum.Struct.Message{}}
  end
  def delete_message(channel_id, message_id) do
    send(self(), {channel_id, message_id})
    :ok
  end
  def create_dm(author_id) do
    send(self(), {author_id})
    {:ok, %Nostrum.Struct.Channel{id: 456}}
  end
end
