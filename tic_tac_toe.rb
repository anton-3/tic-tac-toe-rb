# frozen_string_literal: true

# module for the classes that need logic with boards
# expects a @board instance variable
module BoardEditable
  private

  def print_board(board = @board)
    puts
    puts '     1   2   3'
    puts
    board.each_with_index do |row, row_idx|
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

  def game_over?(brd = @board)
    return true if three_in_a_row?(brd) || three_in_a_col?(brd) || three_in_a_diag?(brd)

    board_full?(brd) ? 'tie' : false
  end

  def three_in_a_row?(brd)
    brd[0].all?('X') || brd[0].all?('O') ||
      brd[1].all?('X') || brd[1].all?('O') ||
      brd[2].all?('X') || brd[2].all?('O')
  end

  def three_in_a_col?(brd)
    column(1, brd).all?('X') || column(1, brd).all?('O') ||
      column(2, brd).all?('X') || column(2, brd).all?('O') ||
      column(3, brd).all?('X') || column(3, brd).all?('O')
  end

  def three_in_a_diag?(brd)
    center = brd[1][1]
    return false if center == ' '

    (brd[0].first == center && center == brd[2].last) ||
      (brd[2].first == center && center == brd[0].last)
  end

  def board_full?(brd)
    brd[0].none?(' ') && brd[1].none?(' ') && brd[2].none?(' ')
  end

  def winner(board = @board)
    x_move_count = 0
    o_move_count = 0

    board.each do |row|
      row.each do |cell|
        x_move_count += 1 if cell == 'X'
        o_move_count += 1 if cell == 'O'
      end
    end

    # the last player to move is the winner, X moves first
    x_move_count > o_move_count ? 'X' : 'O'
  end

  def column(num, brd = @board)
    [brd[0][num - 1], brd[1][num - 1], brd[2][num - 1]]
  end
end

# handles game logic
class Game
  include BoardEditable

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

  def set_cell(coords, value)
    @board[coords[0]][coords[1]] = value
  end

  def finish
    return 'Tie!' if game_over? == 'tie'

    "#{winner} wins!"
  end
end

# handles logic for all players
class Player
  def initialize(move_type)
    @move_type = move_type.upcase
  end

  def move(board)
    cell = []

    loop do
      cell = [Random.rand(3), Random.rand(3)]
      break if board[cell[0]][cell[1]] == ' '
    end

    declare_move(cell)
    cell
  end

  def self.new_player(move_type)
    player_type = ''

    loop do
      puts "Player #{move_type.upcase}: human or computer?"
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
  include BoardEditable

  SCORES = {
    X: 1,
    O: -1,
    tie: 0
  }.freeze

  def move(board)
    @board = board.clone

    best_move = find_best_move(@move_type == 'X')
    declare_move(best_move)
    best_move
  end

  private

  def find_best_move(is_maximizer)
    # hard code the first move for computer X because my minimax is slow
    return [0, 0] if is_maximizer && @board.all?([' ', ' ', ' '])

    best_move = nil

    @board.each_with_index do |row, row_idx|
      row.each_with_index do |cell, cell_idx|
        next unless cell == ' '

        current_move = [row_idx, cell_idx]
        best_move = current_move if best_move.nil?
        current_move_score = minimax(!is_maximizer, make_new_board(current_move))
        return current_move if current_move_score == SCORES[@move_type.to_sym]

        best_move_score = minimax(!is_maximizer, make_new_board(best_move))

        if is_maximizer && current_move_score > best_move_score
          best_move = current_move
        elsif !is_maximizer && current_move_score < best_move_score
          best_move = current_move
        end
      end
    end

    best_move
  end

  def minimax(is_maximizer, board, depth = 0)
    game_over = game_over?(board)
    return evaluate(board, game_over) if [true, 'tie'].include?(game_over)

    scores = []

    if is_maximizer

      board.each_with_index do |row, row_idx|
        row.each_with_index do |cell, cell_idx|
          next unless cell == ' '

          score = minimax(false, make_new_board([row_idx, cell_idx], 'X', board), depth + 1)
          scores << score
        end
      end

    else

      board.each_with_index do |row, row_idx|
        row.each_with_index do |cell, cell_idx|
          next unless cell == ' '

          score = minimax(true, make_new_board([row_idx, cell_idx], 'O', board), depth + 1)
          scores << score
        end
      end

    end

    is_maximizer ? scores.max : scores.min
  end

  def evaluate(board, game_over)
    # each final game position has a score assigned to it
    game_over == 'tie' ? SCORES[:tie] : SCORES[winner(board).to_sym]
  end

  def make_new_board(cell, move = @move_type, board = @board)
    # this creates a deep copy which is necessary for a 2D array
    new_board = Marshal.load(Marshal.dump(board))
    new_board[cell[0]][cell[1]] = move
    new_board
  end

  def declare_move(cell)
    puts "Computer #{@move_type} plays row #{cell[0] + 1}, column #{cell[1] + 1}"
  end
end

# Player.new_player allows choice from user between computer and human
player_x = Player.new_player('x')
player_o = Player.new_player('o')
game = Game.new(player_x, player_o)
game.play
