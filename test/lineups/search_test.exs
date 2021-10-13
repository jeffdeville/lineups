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

    @tag timeout: :infinity
    test "when num iterations not completed, search" do
      lineups = Search.init(@player_skills, 8)
      initial_score = Search.score(lineups, @player_skills)
      new_lineups = Search.search(lineups, initial_score, @player_skills, 10000, 0)
      Search.print(new_lineups)
      IO.inspect([Search.score(new_lineups, @player_skills), Search.score(lineups, @player_skills)], label: "New Score, Original Score")
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

  describe "score_player_position" do
    test "test scoring one player precisely" do
      player_skill = Nx.tensor([0, 5, 4, 5, 4, 5])
      position_skill_weights = Nx.tensor([0, 1, 0.3, 1, 1, 1])
      tiredness_skill_weights = Nx.tensor([0, 0.5, 0.5, 1, 0.95, 0.3])

      result = Search.score_player_position(player_skill, position_skill_weights, tiredness_skill_weights, 1) |> Nx.to_scalar() |> Float.round(3)
      assert result == 0.94

      result = Search.score_player_position(player_skill, position_skill_weights, tiredness_skill_weights, 0.8) |> Nx.to_scalar() |> Float.round(3)
      assert result == 0.815
    end
  end

  describe "calculate_energy_level" do
    test "calculates energy level at beginning of game to be 1" do
      assert Search.calculate_energy_level([]) == 1
    end
    test "calculates energy level in middle of game" do
      goalie = 0
      def1 = 1
      def2 = 2
      stopper = 3
      def_mid = 4
      off_mid = 5
      fwd = 6
      bench = 7

      assert Search.calculate_energy_level([bench]) == 1
      assert Search.calculate_energy_level([bench, bench]) == 1
      assert Search.calculate_energy_level([goalie, goalie]) == 1
      assert Search.calculate_energy_level([stopper]) < 1
      assert Search.calculate_energy_level([stopper, bench]) > Search.calculate_energy_level([bench, stopper])
      assert Search.calculate_energy_level([stopper, stopper]) < Search.calculate_energy_level([stopper])
      assert Search.calculate_energy_level([stopper, fwd ]) == 0.5
      assert Search.calculate_energy_level([fwd, fwd, fwd, fwd, fwd ]) < Search.calculate_energy_level([fwd, fwd, fwd, fwd ])
    end
  end
  describe "score" do
    test "test scoring one player precisely" do
      player_skill = Nx.tensor([[0, 5, 4, 5, 4, 5]])
      position_skill_weights = Nx.tensor([[0, 1, 0.3, 1, 1, 1]])
      tiredness_skill_weights = Nx.tensor([0, 0.5, 0.5, 5, 4.5, 1.5])

      lineup =
        Nx.tensor(
          # lineup
          [
            # players
            [
              # positions
              [
                1
              ]
            ]
          ]
        )

      result = Search.score(lineup, player_skill, position_skill_weights)
      assert result == 0.94
    end

    test "test scoring multiple players precisely" do
      skills = Nx.tensor([
        [0, 5, 4, 5, 4, 5],
        [5, 3, 3, 3, 3, 3],
      ])
      weightings = Nx.tensor([
        [1, 0, 0, 0, 0, 0],
        [0, 1, 0.3, 1, 1, 1]
      ])

      lineup =
        Nx.tensor(
          # lineup
          [
            # players
            [
              # positions
              [ 0, 1 ], # Breccan is stopper
              [ 1, 0 ], # Cameron is goalie
            ]
          ]
        )

      result = Search.score(lineup, skills, weightings)
      assert result == 1.94
    end

    test "test scoring multiple players and lineups" do
      skills = Nx.tensor([
        [0, 5, 4, 5, 4, 5],
        [5, 3, 3, 3, 3, 3],
      ])
      weightings = Nx.tensor([
        [1, 0, 0, 0, 0, 0],
        [0, 1, 0.3, 1, 1, 1]
      ])
      position_exhaustion = Nx.tensor([
        [0, 0, 0, 0, 0, 0, 0, 0],
        [0.6, 0.20, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
      ])

      lineup =
        Nx.tensor(
          # lineup
          [
            # players
            [
              # positions
              [ 0, 1 ], # Breccan is stopper
              [ 1, 0 ], # Cameron is goalie
            ],
            [
              # positions
              [ 0, 1 ], # Breccan is goalie
              [ 1, 0 ], # Cameron is stopper
            ]
          ]
        )

      result = Search.score(lineup, skills, weightings, position_exhaustion)
      assert result < 3.879
    end
  end
end
