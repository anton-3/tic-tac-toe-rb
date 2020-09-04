# frozen_string_literal: true

# handles game logic
class Game
  def initialize(player_x = Player.new('x'), player_o = Player.new('o'))
    @player_x = player_x
    @player_o = player_o
    @outcome = ''
    @board = [[' ', ' ', ' '], [' ', ' ', ' '], [' ', ' ', ' ']] # @board[row][col] to access cell
  end

  def play
    print_board

    until game_over?
      # X must move first for winner check
      x_move = @player_x.move(@board)
      set_cell(x_move, 'X')
      print_board

      break if game_over?

      o_move = @player_o.move(@board)
      set_cell(o_move, 'O')
      print_board
    end

    puts finish
  end

  private

  def print_board
    puts
    puts '     1   2   3'
    puts
    @board.each_with_index do |row, row_idx|
      print " #{row_idx + 1}  "
      row.each_with_index do |cell, cell_idx|
        print " #{cell} "
        print '|' unless cell_idx == 2
      end
      puts "\n    -----------" unless row_idx == 2
    end
    2.times { puts } # last board row has no appended newline
    sleep 1
  end

  def set_cell(coords, value)
    @board[coords[0]][coords[1]] = value
  end

  def game_over?
    three_in_a_row? || three_in_a_col? || three_in_a_diag? || board_full?
  end

  def finish
    return 'Tie!' if @outcome == 'tie'

    x_move_count = 0
    o_move_count = 0

    @board.each do |row|
      row.each do |cell|
        x_move_count += 1 if cell == 'X'
        o_move_count += 1 if cell == 'O'
      end
    end

    # the last player to move is the winner, X moves first
    winner = x_move_count > o_move_count ? 'Player X' : 'Player O'
    "#{winner} wins!"
  end

  def three_in_a_row?
    row(1).all?('X') || row(1).all?('O') ||
      row(2).all?('X') || row(2).all?('O') ||
      row(3).all?('X') || row(3).all?('O')
  end

  def three_in_a_col?
    col(1).all?('X') || col(1).all?('O') ||
      col(2).all?('X') || col(2).all?('O') ||
      col(3).all?('X') || col(3).all?('O')
  end

  def three_in_a_diag?
    center = row(2)[1]
    return false if center == ' '

    (row(1).first == center && center == row(3).last) ||
      (row(3).first == center && center == row(1).last)
  end

  def board_full?
    full = row(1).none?(' ') && row(2).none?(' ') && row(3).none?(' ')

    @outcome = 'tie' if full
    full
  end

  def row(num)
    @board[num - 1]
  end

  def col(num)
    [row(1)[num - 1], row(2)[num - 1], row(3)[num - 1]]
  end
end

# handles logic for all players
class Player
  def initialize(move_type)
    @move_type = move_type.upcase
  end

  def move(board)
    loop do
      cell = [Random.rand(3), Random.rand(3)]
      break if board[cell[0]][cell[1]] == ' '
    end

    declare_move(cell)
    cell
  end

  def self.get_new_player(move_type)
    player_type = ''

    loop do
      puts "Player #{move_type}: human or computer?"
      player_type = gets.chomp.downcase
      break if %w[human h computer c].include?(player_type)

      puts 'Invalid input!'
    end

    case player_type
    when 'h' || 'human'
      HumanPlayer.new(move_type)
    when 'c' || 'computer'
      ComputerPlayer.new(move_type)
    else
      Player.new(move_type)
    end
  end

  private

  def declare_move(cell)
    puts "Player #{@move_type} plays row #{cell[0] + 1}, column #{cell[1] + 1}"
  end
end

# handles all human players
class HumanPlayer < Player
  def move(board)
    cell = Array.new(2)

    loop do
      cell.fill(nil)
      puts "Player #{@move_type}: Enter your move (row, col)"
      input = gets.chomp
      row = input[0]
      col = input[-1]
      cell[0] = row.to_i - 1 if row.to_i.to_s == row && (1..3).include?(row.to_i)
      cell[1] = col.to_i - 1 if col.to_i.to_s == col && (1..3).include?(col.to_i)

      begin
        break if board[cell[0]][cell[1]] == ' '
      rescue StandardError
        puts 'Illegal move!'
      else
        puts 'Illegal move!'
      end
    end

    puts
    declare_move(cell)
    cell
  end
end

# handles all computer players
class ComputerPlayer < Player
  private

  def declare_move(cell)
    puts "Computer #{@move_type} plays row #{cell[0] + 1}, column #{cell[1] + 1}"
  end
end

# Player.get_new_player allows choice from user between computer and human
player_x = Player.get_new_player('x')
player_o = Player.get_new_player('o')
game = Game.new(player_x, player_o)
game.play
