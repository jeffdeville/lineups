defmodule Lineups.SearchTest do
  use ExUnit.Case, async: true
  alias Lineups.Search
  @position_skills Nx.tensor(
  [
    [1, 0, 0, 0, 0, 0, 0], # goalie
    [0, 1, 0, 0, 0, 0, 0], # def1
    [0, 1, 0, 0, 0, 0, 0], # def2
    [0, 1, 0.3, 1, 1, 1, 0], # stopper
    [0, 1, 0.6, 1, 0.7, 0.4, 0], # def_mid
    [0, 0.4, 1, 1, 1, 0.9, 0], # off_mid
    [0, 0, 1, 0.5, 1, 1, 0], # fwd
    [0, 0, 0, 0, 0, 0, 1], # sub1
    [0, 0, 0, 0, 0, 0, 1], # sub2
    [0, 0, 0, 0, 0, 0, 1], # sub3
    [0, 0, 0, 0, 0, 0, 1], # sub4
    [0, 0, 0, 0, 0, 0, 1], # sub5
    [0, 0, 0, 0, 0, 0, 1], # sub6
  ],
  names: [:position, :skill_weighting]
  )
  describe "init" do
    test "creates the initial board with the number of positions from the weighting map, and the num periods passed in" do
      lineups = Search.init(@position_skills, 3)
      assert Nx.shape(lineups) == {3, 13, 13}

      lineups = Search.init(@position_skills, 6)
      assert Nx.shape(lineups) == {6, 13, 13}
    end
  end

  describe "search" do
    test "when num iterations is reached, return current state" do
      lineups = Search.init(@position_skills, 3)
      new_lineups = Search.search(lineups, 0, nil, @position_skills, 10, 10)

      assert new_lineups == lineups
    end

    test "when num iterations not completed, search" do
      lineups = Search.init(@position_skills, 3)
      new_lineups = Search.search(lineups, 0, nil, @position_skills, 10, 0)

      assert new_lineups == lineups
    end
  end

  describe "mutate" do
    test "randomly alter a lineup in just 1 characteristic" do
      lineups = Search.init(@position_skills, 3)

      new_lineups = Search.mutate(lineups, 1, [0, 1, 3, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12])
      IO.inspect(new_lineups, limit: :infinity)
      assert lineups != new_lineups
    end
  end
end
