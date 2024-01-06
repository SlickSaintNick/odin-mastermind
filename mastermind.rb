# frozen_string_literal: true

# For emoji characters, PIECE_TYPE = 0. For no emojis, PIECE_TYPE = 1
PIECE_TYPE = 0

# Initialize the length and complexity of the game.
# Game pieces have a print value, an index in the array which corresponds
# to the game state arrays, and a letter value.

# The GUESS_PIECE letter value is used for player input - e.g. to choose:
# "RED RED GREEN BLUE" type "rrgb" or "RRGB". In most cases GUESS_PIECEs are not hardcoded,
# the exception being the board display.

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

  def display_board(reveal_code = false, code = nil)
    # Display the mystery code box and the board rows
    display_code_box(reveal_code, code)
    display_rows
    # Display the (hard-coded) list of options.
    puts "\n🔴 Red    🔵 Blue   🟡 Yellow"
    puts '🟢 Green  ⚪ White  🟣 Purple'
  end

  def display_code_box(reveal_code, code)
    print '              '
    if reveal_code
      POSITIONS.times { |i| print "#{GUESS_PIECES[code[i]][PIECE_TYPE]} " }
      print "\n\n"
    else
      print "❔ ❔ ❔ ❔\n\n"
    end
  end

  def display_rows
    TURNS.times do |i|
      if 11 - i < 9
        print '   '
      else
        print '  '
      end
      print "#{TURNS - i} "
      POSITIONS.times do |j|
        print FEEDBACK_PIECES[@board_feedback[i][j]][PIECE_TYPE]
      end
      print '|'
      POSITIONS.times do |j|
        print GUESS_PIECES[@board_guess[i][j]][PIECE_TYPE]
        print ' '
      end
      print "\n"
    end
  end

  def update_board(turn, guess, feedback)
    # Add the guesses to the array
    guess.each_with_index do |number, i|
      @board_guess[11 - turn][i] = number
    end
    # Add the feedback to the array
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
  # Purpose: Remember and update the game statistics, display them.
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
    @total_score += turn if correct_guess
    @best_score = turn if correct_guess && turn < @best_score
  end
end

class CodeSetter
  def initialize
    @code = []
  end

  def check_code(guess, code = @code)
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

class CodeSetterComputer < CodeSetter
  # Purpose: Set the code and check guesses, providing feedback.
  attr_reader :code

  def set_code
    # Set the code of length POSITIONS, as an array of random numbers. E.g. [3, 2, 5, 5]
    @code = []
    POSITIONS.times do
      @code.push((rand * (GUESS_PIECES.length - 1)).floor + 1)
    end
    @code
  end
end

class CodeSetterHuman < CodeSetter
  attr_reader :code

  def initialize
    # Build a regex expression to test valid input.
    @guess_validation_re = '['
    GUESS_PIECES.each { |piece| @guess_validation_re += piece[1] }
    @guess_validation_re += "]{#{POSITIONS}}"
  end

  def set_code()
    # Display the (hard-coded) list of options.
    puts "CODE COLOUR OPTIONS:\n\n"
    puts '🔴 Red    🔵 Blue   🟡 Yellow'
    puts '🟢 Green  ⚪ White  🟣 Purple'
    puts "\nType your #{POSITIONS}-color code as the first letter of each color.\n"
    puts "E.g. for 🔴⚪🔵🔴 type >> RWBR\n\n"

    loop do
      print "Your code >> "
      input = gets.chomp.upcase.strip
      Kernel.exit if input == 'EXIT'
      if input.slice(0, POSITIONS).match(@guess_validation_re)
        @code = convert_code(input.slice(0, POSITIONS))
        return @code
      end
      puts "Type your code as #{POSITIONS} letters where each letter is the first letter of a color."
    end
  end

  def convert_code(str)
    # Converts a letter code sequence of pieces to array of indexes e.g. "RGBR" -> [1, 2, 3, 1]
    str.split('').map { |c| GUESS_PIECES.find_index { |piece| piece[1] == c } }
  end
end

class CodeBreakerHuman
  # Purpose: Guess the code

  def initialize
    # Build a regex expression to test valid input.
    @guess_validation_re = '['
    GUESS_PIECES.each { |piece| @guess_validation_re += piece[1] }
    @guess_validation_re += "]{#{POSITIONS}}"
  end

  def guess(turn, _game_board=nil, _code_setter=nil)
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
    # Converts a letter code sequence of pieces to array of indexes e.g. "RGBR" -> [1, 2, 3, 1]
    str.split('').map { |c| GUESS_PIECES.find_index { |piece| piece[1] == c } }
  end
end

class CodeBreakerComputer
  # Purpose: Use algorithm to guess the code

  def guess(turn, game_board, code_setter)
    return first_guess if turn.zero?

    subsequent_guess(turn, game_board, code_setter)
  end

  def first_guess
    guess = []
    POSITIONS.times do
      guess.push((rand * (GUESS_PIECES.length - 1)).floor + 1)
    end
    print "\nPress Enter for next computer guess >> "
    gets
    guess
  end

  def subsequent_guess(turn, game_board, code_setter)
    # Generate an array of all possible codes where the current board state would allow that code.
    viable_codes = []

    (1..GUESS_PIECES.length - 1).each do |pos1|
      (1..GUESS_PIECES.length - 1).each do |pos2|
        (1..GUESS_PIECES.length - 1).each do |pos3|
          (1..GUESS_PIECES.length - 1).each do |pos4|
            # Here we have a code generated. Check if it is viable.
            this_code = [pos1, pos2, pos3, pos4]
            viable_codes.push(this_code) if code_viable?(this_code, turn, game_board, code_setter)
          end
        end
      end
    end
    # We now have a list of all possible codes. Display them...
    display_viable_codes(viable_codes)

    # Return a random viable code.
    print "\nPress Enter for next computer guess >> "
    gets
    viable_codes.sample
  end

  def code_viable?(this_code, turn, game_board, code_setter)
    (12 - turn..11).each do |row|
      row_feedback = game_board.board_feedback[row]
      row_guess = game_board.board_guess[row]
      # Logic here:
      # We have a possible code (this_code).
      # If it were the actual code, would it have led to the feedback on this row, given the guess on this row?
      # If not, it is not viable. Discard it. If it passes all checks, add it to the list of possibilities.
      return false if code_setter.check_code(row_guess, this_code) != row_feedback
    end
    true
  end

  def display_viable_codes(viable_codes)
    count = viable_codes.length
    if count > 20
      puts "\nThere are #{count} viable guesses. The first 20 are:"
      20.times do |i|
        POSITIONS.times do |j|
          print GUESS_PIECES[viable_codes[i][j]][PIECE_TYPE]
        end
        if i < 19
          print ', '
        else
          print '...'
        end
        if (i + 1) % 5 == 0
          print "\n"
        end
      end
    elsif count > 1
      puts "\nThere are #{count} viable guesses. They are:"
      count.times do |i|
        POSITIONS.times do |j|
          print GUESS_PIECES[viable_codes[i][j]][PIECE_TYPE]
        end
        if i < count - 1
          print ', '
        end
        if (i + 1) % 5 == 0
          print "\n"
        end
      end
    else
      puts "\nThere is 1 viable guess:"
      POSITIONS.times do |j|
        print GUESS_PIECES[viable_codes[0][j]][PIECE_TYPE]
      end
    end
  end
end

class Game
  # Purpose: Control the flow of the game, determine the result.

  def initialize(code_breaker_or_setter = 'breaker')
    @game_board = GameBoard.new
    @score_board = ScoreBoard.new
    if code_breaker_or_setter == 'breaker'
      @code_breaker = CodeBreakerHuman.new
      @code_setter = CodeSetterComputer.new
    elsif code_breaker_or_setter == 'setter'
      @code_breaker = CodeBreakerComputer.new
      @code_setter = CodeSetterHuman.new
    end
  end

  def play_game
    refresh_display
    display_title
    @code_setter.set_code

    # Main game loop.
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
    puts "
___  ___          _             ___  ____           _
|  \\/  |         | |            |  \\/  (_)         | |
| .  . | __ _ ___| |_ ___ _ __  | .  . |_ _ __   __| |
| |\\/| |/ _` / __| __/ _ \\ '__| | |\\/| | | '_ \\ / _` |
| |  | | (_| \\__ \\ ||  __/ |    | |  | | | | | | (_| |
\\_|  |_/\\__,_|___/\\__\\___|_|    \\_|  |_/_|_| |_|\\__,_|"
    puts "\n\n"
  end

  def self.code_breaker_or_setter
    puts 'Setter - You set the code'
    puts 'Breaker - You break the code'
    puts 'Exit'
    loop do
      print "\n>> "
      input = gets.chomp.downcase.strip
      Kernel.exit if input == 'exit'
      return 'setter' if input.slice(0) == 's'

      return 'breaker' if input.slice(0) == 'b'
    end
  end
end

game = Game.new(Game.code_breaker_or_setter)

loop do
  game.play_game
end
