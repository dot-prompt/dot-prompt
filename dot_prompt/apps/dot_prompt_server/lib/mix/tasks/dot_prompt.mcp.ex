defmodule Mix.Tasks.DotPrompt.Mcp do
  @moduledoc """
  Mix task to run the MCP server for dot-prompt.
  """
  use Mix.Task

  @shortdoc "Runs the MCP server"

  def run(_args) do
    # Application needs to be started
    Mix.Task.run("app.start")
    DotPromptServer.MCP.Server.start()
  end
end
