# frozen_string_literal: true

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

code = [4, 5, 1, 4] # WYRW
p code

board_guess = Array.new(TURNS) { Array.new(POSITIONS, 0) }
board_feedback = Array.new(TURNS) { Array.new(POSITIONS, 0) }

def update_board(turn, guess, feedback, board_guess, board_feedback)
  # Add the guesses to the array
  guess.each_with_index do |number, i|
    board_guess[turn][i] = number
  end
  # Add the feedback to the arrau
  feedback.each_with_index do |number, i|
    board_feedback[turn][i] = number
  end
end

def check_code(guess, code)
  # Check the guess against the code and provide feedback. Feedback in the form of a sorted
  # array referencing FEEDBACK_PIECES, E.g. 1 correct, 2 right colour, 1 incorrect would be:
  # [2, 1, 1, 0]. I.e. if all are [2], game is won.
  guess_copy = guess[0..(guess.length - 1)]
  code_copy = code[0..(code.length - 1)]
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

def computer_guess(turn, board_guess, board_feedback)
  guess = []
  POSITIONS.times do
    guess.push((rand * (GUESS_PIECES.length - 1)).floor + 1)
  end
  feedback = check_code(guess, [4, 5, 1, 4])
  p "My feedback will be #{feedback}"
  guess
end


guess = computer_guess(0, board_guess, board_feedback)
p guess
feedback = check_code(guess, code)
p feedback
update_board(0, guess, feedback, board_guess, board_feedback)
p board_guess
p board_feedback
