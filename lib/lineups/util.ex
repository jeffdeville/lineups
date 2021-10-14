defmodule Lineups.Util do
  def get_position_index(position) do
    {num_positions} = Nx.shape(position)

    position
    |> Nx.multiply(Nx.iota({num_positions}))
    |> Nx.sum()
    |> Nx.to_scalar()
  end

  def get_previous_player_positions(_lineups, _player, 0), do: []

  def get_previous_player_positions(lineups, player, current_period) do
    0..(current_period - 1)
    |> Enum.map(fn period ->
      # IO.inspect(lineups[period][player], label: "Last Position")
      lineups[period][player] |> get_position_index()
    end)
  end
end
