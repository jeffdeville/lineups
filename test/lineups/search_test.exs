defmodule Lineups.SearchTest do
  use ExUnit.Case, async: true
  alias Lineups.Search

  @player_skills Nx.tensor([
                   # Breccan
                   [0, 5, 4, 5, 4, 5],
                   # Cameron
                   [5, 3, 3, 3, 3, 3],
                   # Evan
                   [4, 4, 4, 2, 2, 4],
                   # Harry
                   [3, 4, 3, 4, 3, 2],
                   # Isaiah
                   [0, 4, 3, 4, 4, 3],
                   # Jack
                   [4, 5, 4, 3, 3, 4],
                   # Linsana
                   [0, 5, 5, 5, 5, 5],
                   # Lusaine
                   [0, 5, 5, 5, 5, 5],
                   # Paco
                   [0, 3, 3, 5, 3, 3],
                   # Richard
                   [0, 2, 1, 2, 1, 1],
                   # Ryan
                   [0, 2, 2, 2, 1, 3],
                   # SamK
                   [0, 3, 4, 4, 4, 3],
                   # SamS
                   [0, 2, 3, 4, 5, 2]
                 ])
  @position_skills Nx.tensor(
                     [
                       # goalie
                       [1, 0, 0, 0, 0, 0],
                       # def1
                       [0, 1, 0, 0, 0, 0],
                       # def2
                       [0, 1, 0, 0, 0, 0],
                       # stopper
                       [0, 1, 0.3, 1, 1, 1],
                       # def_mid
                       [0, 1, 0.6, 1, 0.7, 0.4],
                       # off_mid
                       [0, 0.4, 1, 1, 1, 0.9],
                       # fwd
                       [0, 0, 1, 0.5, 1, 1],
                       # sub1
                       [0, 0, 0, 0, 0, 0],
                       # sub2
                       [0, 0, 0, 0, 0, 0],
                       # sub3
                       [0, 0, 0, 0, 0, 0],
                       # sub4
                       [0, 0, 0, 0, 0, 0],
                       # sub5
                       [0, 0, 0, 0, 0, 0],
                       # sub6
                       [0, 0, 0, 0, 0, 0]
                     ],
                     names: [:position, :skill_weighting]
                   )
  @breccan 0
  @cameron 1
  @evan 2
  @harry 3
  @isaiah 4
  @jack 5
  @linsana 6
  @lusaine 7
  @paco 8
  @richard 9
  @ryan 10
  @samK 11
  @samS 12

  @nopos Nx.tensor([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  @goalie Nx.tensor([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  @def1 Nx.tensor([0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  @def2 Nx.tensor([0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  @stopper Nx.tensor([0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0])
  @def_mid Nx.tensor([0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0])
  @off_mid Nx.tensor([0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0])
  @fwd Nx.tensor([0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0])
  @sub1 Nx.tensor([0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0])
  @sub2 Nx.tensor([0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0])
  @sub3 Nx.tensor([0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0])
  @sub4 Nx.tensor([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0])
  @sub5 Nx.tensor([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0])
  @sub6 Nx.tensor([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])

  describe "init" do
    test "creates the initial board with the number of positions from the weighting map, and the num periods passed in" do
      lineups = Search.init(@player_skills, 3)
      assert Nx.shape(lineups) == {3, 13, 13}

      lineups = Search.init(@player_skills, 6)
      assert Nx.shape(lineups) == {6, 13, 13}
    end
  end

  describe "search" do
    test "when num iterations is reached, return current state" do
      lineups = Search.init(@player_skills, 3)
      new_lineups = Search.search(lineups, 0, @player_skills, 10, 10)

      assert new_lineups == lineups
    end

    test "when num iterations not completed, search" do
      lineups = Search.init(@player_skills, 2)
      initial_score = Search.score(lineups, @player_skills)
      new_lineups = Search.search(lineups, initial_score, @player_skills, 50000, 0)
      Search.print(new_lineups)
      assert Search.score(new_lineups, @player_skills) > Search.score(lineups, @player_skills)
      assert false
    end
  end

  describe "evolve" do
    test "randomizes as expected" do
      :rand.seed(:exsss, {100, 101, 102})
      lineups = Search.init(@player_skills, 3)
      new_lineups = Search.evolve(lineups)
      assert lineups[0] == new_lineups[0]
      assert lineups[2] == new_lineups[2]

      assert lineups[1] !=
               Nx.tensor([
                 [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
               ])
    end
  end

  describe "mutate" do
    test "randomly alter a lineup in just 1 characteristic" do
      lineups = Search.init(@player_skills, 3)
      new_lineups = Search.mutate(lineups, 1, [0, 1, 3, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12])
      assert lineups[0] == new_lineups[0]
      assert lineups[2] == new_lineups[2]

      assert lineups[1] !=
               Nx.tensor([
                 [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
                 [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]
               ])
    end
  end

  describe "score" do
    test "scores correctly" do
      lineups = Search.init(@player_skills, 3)
      score = Search.score(lineups, @player_skills)
      assert score == 7.569902420043945
    end

    def make_lineup(stuff) do
      lineup =
        0..12
        |> Enum.map(fn player ->
          player_pos =
            Enum.find(stuff, fn
              {^player, position} -> true
              _ -> false
            end)

          if player_pos, do: elem(player_pos, 1), else: @nopos
        end)
        |> Nx.stack()
        |> Nx.broadcast({1, 13, 13})
    end

    test "simple choose the better lineup" do
      stopper = make_lineup([{@breccan, @stopper}])
      goalie = make_lineup([{@breccan, @goalie}])
      def1 = make_lineup([{@breccan, @def1}])

      stopper_score = Search.score(stopper, @player_skills)
      goalie_score = Search.score(goalie, @player_skills)
      def1_score = Search.score(def1, @player_skills)

      assert goalie_score == 0
      assert def1_score < stopper_score
    end

    test "multi-player choose the better lineup" do
      bad = make_lineup([{@breccan, @stopper}])
      bad_score = Search.score(bad, @player_skills)

      good =
        make_lineup([
          {@breccan, @stopper},
          {@linsana, @fwd},
          {@lusaine, @off_mid}
        ])

      good_score = Search.score(good, @player_skills)
      assert good_score > bad_score
    end
  end
end
