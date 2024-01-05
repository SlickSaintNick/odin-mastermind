# frozen_string_literal: true

# Initialize the length and complexity of the game.
# Game pieces have a print value, an index in the array which corresponds
# to the game state arrays, and a letter value.

# The GUESS_PIECE letter value is used for player input - e.g. to choose:
# "RED RED GREEN BLUE" type "rrgb" or "RRGB".

TURNS = 12
POSITIONS = 4
GUESS_PIECES = [
  ['', ''], # 0
  ['🔴', 'R'], # 1
  ['🟢', 'G'], # 2
  ['🔵', 'B'], # 3
  ['⚪', 'W'], # 4
  ['🟡', 'Y'], # 5
  ['🟣', 'P']  # 6
].freeze
FEEDBACK_PIECES = [
  ['➖', '-'],  # 0 - blank
  ['🔲', 'O'],  # 1 - correct color, wrong position
  ['🔳', 'X']   # 2 - correct color and position
].freeze

class GameBoard
  # Purpose: Remember the state of the board, update it, and display it.
  attr_reader :board_guess, :board_feedback

  def initialize
    @board_guess = Array.new(TURNS) { Array.new(POSITIONS, 0) }
    @board_feedback = Array.new(TURNS) { Array.new(POSITIONS, 0) }
  end

  def display_board(reveal_code=false, code=nil)
    # Print the code box
    print '              '
    if reveal_code
      POSITIONS.times { |i| print "#{GUESS_PIECES[code[i]][0]} " }
      print "\n\n"
    else
      print "❔ ❔ ❔ ❔\n\n"
    end
    # Print the rows
    TURNS.times do |i|
      if 11 - i < 9
        print '   '
      else
        print '  '
      end
      print "#{TURNS - i} "
      POSITIONS.times do |j|
        print FEEDBACK_PIECES[@board_feedback[i][j]][0]
      end
      print '|'
      POSITIONS.times do |j|
        print GUESS_PIECES[@board_guess[i][j]][0]
        print ' '
      end
      print "\n"
    end
    # Print the list of options.
    puts "\n🔴 Red    🔵 Blue   🟡 Yellow"
    puts '🟢 Green  ⚪ White  🟣 Purple'
  end

  def update_board(turn, guess, feedback)
    # Add the guesses to the array
    guess.each_with_index do |number, i|
      @board_guess[11 - turn][i] = number
    end
    # Add the feedback to the arrau
    feedback.each_with_index do |number, i|
      @board_feedback[11 - turn][i] = number
    end
  end

  def clear_board
    @board_guess.replace(Array.new(TURNS) { Array.new(POSITIONS, 0) })
    @board_feedback.replace(Array.new(TURNS) { Array.new(POSITIONS, 0) })
  end
end

class ScoreBoard
  # Remember and update the game statistics, display them.
  def initialize
    @rounds = 0
    @correct = 0
    @total_score = 0
    @best_score = TURNS + 1
  end

  def display_stats
    puts "ROUNDS:\t#{@rounds}\tCORRECT:\t#{@correct}"
    puts "TOTAL:\t#{@total_score}\tBEST:\t\t#{
      @best_score if @best_score <= TURNS
    }\n\n\n"
  end

  def update_stats(turn, correct_guess)
    @rounds += 1
    @correct += 1 if correct_guess
    @total_score += turn
    @best_score = turn if correct_guess && turn < @best_score
  end
end

class CodeSetter
  # Set the code and check guesses, providing feedback.
  attr_reader :code

  def initialize
    @code = []
  end

  def set_code
    # Set the code of length POSITIONS, as an array of random numbers. E.g. [3, 2, 5, 5]
    @code = []
    POSITIONS.times do
      @code.push((rand * (GUESS_PIECES.length - 1)).floor + 1)
    end
    @code
  end

  def check_code(guess, code=@code)
    # Check the guess against the code and provide feedback. Feedback in the form of a sorted
    # array referencing FEEDBACK_PIECES, E.g. 1 correct, 2 right colour, 1 incorrect would be:
    # [2, 1, 1, 0]. I.e. if all are [2], game is won.
    guess_copy = guess[0..(guess.length - 1)]
    code_copy = code[0..(@code.length - 1)]
    feedback = []
    # Check for correct colour and position (feedback = 2)
    code_copy.each_with_index do |_, i|
      next unless code_copy[i] == guess_copy[i]

      feedback.push(2)
      guess_copy[i] = 0
      code_copy[i] = 0
    end
    # Check for correct color, wrong position (feedback = 1)
    guess_copy.each_with_index do |number, guess_index|
      next if number.zero?

      next unless (code_index = code_copy.find_index(number))

      feedback.push(1)
      guess_copy[guess_index] = 0
      code_copy[code_index] = 0
    end
    # Check for incorrect (feedback = 0)
    guess_copy.each { |number| feedback.push(0) if number != 0 }

    feedback
  end
end

class CodeBreakerHuman
  # Guess the code

  def initialize
    # Build a regex expression to test valid input.
    @guess_validation_re = '['
    GUESS_PIECES.each { |piece| @guess_validation_re += piece[1] }
    @guess_validation_re += "]{#{POSITIONS}}"
  end

  def guess(turn, game_board, code_setter)
    # Get user input
    loop do
      print "\nTurn #{turn + 1} >> "
      guess = gets.chomp.upcase.strip
      Kernel.exit if guess == 'EXIT'
      return convert_code(guess) if guess.slice(0, POSITIONS).match(@guess_validation_re)

      print "Type your guesses as #{POSITIONS} letters where each letter is the first letter of a color."
    end
  end

  def convert_code(str)
    # Converts a letter code of pieces to array of indexes e.g. "RGBR" -> [1, 2, 3, 1]
    str.split('').map { |c| GUESS_PIECES.find_index { |piece| piece[1] == c } }
  end
end

class CodeBreakerComputer
  def guess(turn, game_board, code_setter)
    return first_guess if turn.zero?
    puts "Previous guesses and feedback"
    (12 - turn..11).each do |row|
      print "Row #{12 - row}  "
      print "Guess #{game_board.board_guess[row]}  "
      print "Feedback #{game_board.board_feedback[row]}\n"
    end

    # Generate an array of all possible guesses where the current board state would allow that guess.
    possible_guess = []

    (1..6).each do |pos1|
      (1..6).each do |pos2|
        (1..6).each do |pos3|
          (1..6).each do |pos4|
            # Here we have a code generated. Check if it is viable.
            this_code = [pos1, pos2, pos3, pos4]
            possible_guess.push(this_code) if code_viable?(this_code, turn, game_board, code_setter)
          end
        end
      end
    end
    # We now have a list of all possible guesses. Return a random one.
    puts "First 20 possible guesses:"
    p possible_guess.slice(0, 20)
    print 'Press Enter for computer guess >>'
    gets
    possible_guess.sample
  end

  def first_guess
    guess = []
    POSITIONS.times do
      guess.push((rand * (GUESS_PIECES.length - 1)).floor + 1)
    end
    print 'Press Enter for computer guess >>'
    gets
    guess
  end

  def code_viable?(this_code, turn, game_board, code_setter)
    (12 - turn..11).each do |row|
      row_feedback = game_board.board_feedback[row]
      row_guess = game_board.board_guess[row]
      # Logic here:
      # We have a possible code (this_code).
      # If it were the actual code, would it have led to the feedback on this row, given the guess on this row?
      # If not, it is not viable.
      return false if code_setter.check_code(row_guess, this_code) != row_feedback
    end
    true
  end
end

class Game
  # Control the flow of the game, determine the result.

  def initialize(code_breaker = 'human')
    @game_board = GameBoard.new
    @score_board = ScoreBoard.new
    @code_setter = CodeSetter.new
    if code_breaker == 'human'
      @code_breaker = CodeBreakerHuman.new
    elsif code_breaker == 'computer'
      @code_breaker = CodeBreakerComputer.new
    end
  end

  def play_game
    @code_setter.set_code

    TURNS.times do |turn|
      refresh_display
      guess = @code_breaker.guess(turn, @game_board, @code_setter)
      feedback = @code_setter.check_code(guess)
      @game_board.update_board(turn, guess, feedback)

      # Next turn unless correct guess.
      next unless feedback.uniq == [2]

      game_over(turn + 1, true)
      return 'CodeSetter'
    end

    # Player is out of turns.
    game_over(TURNS + 1, false)
    'CodeBreaker'
  end

  def refresh_display(reveal_code=false)
    display_title
    @score_board.display_stats
    @game_board.display_board(reveal_code, @code_setter.code)
  end

  def game_over(turns, correct_guess)
    @score_board.update_stats(turns, correct_guess)
    refresh_display(true)
    if correct_guess
      puts "\nCorrect guess!"
    else
      puts "\nOut of turns."
    end
    Kernel.exit unless play_again?
  end

  def play_again?
    @game_board.clear_board
    print "Press Enter to play again or type 'exit' to quit.\n\n>> "
    true unless gets.chomp.upcase.strip == 'EXIT'
  end

  def display_title
    Gem.win_platform? ? (system 'cls') : (system 'clear')
    puts "MASTERMIND\n\n"
  end
end

puts 'Human - Human Code Breaker'
puts 'Computer - Computer Code Breaker'
code_breaker = gets.chomp.downcase

game = Game.new(code_breaker)

loop do
  game.play_game
end
