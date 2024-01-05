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
  # Remember the state of the board, update it, and display it.
  @board_guess = Array.new(TURNS) { Array.new(POSITIONS, 0) }
  @board_feedback = Array.new(TURNS) { Array.new(POSITIONS, 0) }

  def self.display_board(reveal_code=false, code=nil)
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

  def self.update_board(turn, guess, feedback)
    # Add the guesses to the array
    guess.each_with_index do |number, i|
      @board_guess[11 - turn][i] = number
    end
    # Add the feedback to the arrau
    feedback.each_with_index do |number, i|
      @board_feedback[11 - turn][i] = number
    end
  end

  def self.clear_board
    @board_guess.replace(Array.new(TURNS) { Array.new(POSITIONS, 0) })
    @board_feedback.replace(Array.new(TURNS) { Array.new(POSITIONS, 0) })
  end
end

class ScoreBoard
  # Remember and update the game statistics, display them.
  @rounds = 0
  @total_score = 0
  @best_score = 0

  def self.display_stats
    puts "ROUNDS:\t#{@rounds}\tAVG:\t#{
      (@total_score.to_f / @rounds).round(1) unless @rounds.zero?}"
    puts "TOTAL:\t#{@total_score}\tBEST:\t#{@best_score}\n\n\n"
  end

  def self.update_stats(turns)
    # TODO add the update stats method.
  end
end

class Player
end

class CodeSetter < Player
  # Set the code and check guesses, providing feedback.
  attr_reader :code

  @code = []

  def self.set_code
    # Set the code of length POSITIONS, as an array of random numbers. E.g. [3, 2, 5, 5]
    @code = []
    POSITIONS.times do
      @code.push((rand * (GUESS_PIECES.length - 1)).floor + 1)
    end
    p @code # TODO remove at end.
    @code
  end

  def self.check_code(guess)
    # Check the guess against the code and provide feedback. Feedback in the form of a sorted
    # array referencing FEEDBACK_PIECES, E.g. 1 correct, 2 right colour, 1 incorrect would be:
    # [2, 1, 1, 0]. I.e. if all are [2], game is won.
    guess_copy = guess[0..(guess.length - 1)]
    code_copy = @code[0..(@code.length - 1)]
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

class CodeBreaker < Player
  # Guess the code
  # Build a regex expression to test valid input.
  @guess_validation_re = '['
  GUESS_PIECES.each { |piece| @guess_validation_re += piece[1] }
  @guess_validation_re += "]{#{POSITIONS}}"

  def self.guess
    # Get user input
    keep_going = true
    while keep_going
      print "\n>> "
      guess = gets.chomp.upcase.strip
      Kernel.exit if guess == 'EXIT'
      guess = guess.slice(0, POSITIONS)
      if guess.match(@guess_validation_re)
        keep_going = false
      else
        print "Type your guesses as #{POSITIONS} letters where each letter is the first letter of a color."
      end
    end
    guess
  end
end

class Game
  # Control the flow of the game, determine the result.
  def self.play_game
    code = CodeSetter.set_code
    TURNS.times do |i|
      turn = i
      display_title
      ScoreBoard.display_stats
      GameBoard.display_board(true, code)
      guess = convert_code(CodeBreaker.guess)
      feedback = CodeSetter.check_code(guess)
      GameBoard.update_board(turn, guess, feedback)
      if feedback.uniq == [2]
        game_won(i + 1, code)
        return 'CodeSetter'
      end
    end
    puts 'Out of turns!'
    Kernel.exit unless play_again?
    'CodeBreaker'
    # TODO on the last turn, display the board and end of game message.
  end

  def self.convert_code(str)
    # Converts a letter code of pieces to array of indexes e.g. "RGBR" -> [1, 2, 3, 1]
    str.split('').map { |c| GUESS_PIECES.find_index { |piece| piece[1] == c } }
  end

  def self.game_won(turns, code)
    # ScoreBoard.update_stats(turns)
    display_title
    ScoreBoard.display_stats
    GameBoard.display_board(true, code)
    puts "\nCorrect guess!"
    Kernel.exit unless play_again?
  end

  def self.play_again?
    GameBoard.clear_board
    puts "Press Enter to play again or type 'exit' to quit."
    true unless gets.chomp.upcase.strip == 'EXIT'
  end

  def self.display_title
    Gem.win_platform? ? (system 'cls') : (system 'clear')
    puts "MASTERMIND\n\n"
  end

end

loop do
  Game.play_game
end
