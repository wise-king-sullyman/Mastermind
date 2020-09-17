# frozen_string_literal: true

INSTRUCTIONS = <<~INSTRUCTIONS
  The computer will select a random code and you will have a limited number of 
  turns to guess it. After each guess you will receive feedback telling you how 
  many of the numbers in your guess were the correct number in the correct 
  location, and how many of the numbers in your guess were the correct number 
  but located in a different place than in the secret code. If you guess the 
  code you earn 1 point. You then create a secret code and it is up to the 
  computer to guess it. The player with the most points at the end of the game
  wins! Default settings have 12 turns (guesses) per round, a code length of 4, 
  4 rounds per game, allows duplicates and has the AI you are playing against 
  on hard difficulty.
INSTRUCTIONS

# Responsible for operation of each "match" or "round" of the game
class Match
  def initialize(settings)
    @settings = settings
    @match_won = false
    @max_turns = settings[:max_turns]
    @player = Player.new
    @code = Code.new(settings[:code_length], settings[:duplicates])
    @ai = Ai.new(settings)
    @intelligent_ai = settings[:intelligent_ai]
  end

  def play_codebreaker
    guess = codebreaker_loop

    if @match_won
      puts "\n \tCongratulations! #{guess.join} was the code and you got it " \
      "in #{@player.guess_count} guesses!"
      return 1
    end

    puts "\n \tLoser! the code was #{@code.secret.join}"
    0
  end

  def play_codemaker
    p 'Enter code'
    @code.secret = @player.guess(@settings).split('').map(&:to_i)
    @intelligent_ai ? codemaker_loop_hard : codemaker_loop_easy
    unless @match_won
      p "You beat the AI! It wasn't able to guess your code!"
      return 0
    end
    p "The AI cracked the code in #{@ai.guess_count} guesses!"
    1
  end

  private

  def codebreaker_loop
    until @match_won
      guesses_remaining = @max_turns - @player.guess_count
      break if guesses_remaining.zero?

      puts "\n \t#{guesses_remaining} guesses remaining"
      guess = @player.guess(@settings).split('').map(&:to_i)
      @code.feedback(guess)
      @match_won = true if @code.solved?(guess)
    end
    guess
  end

  def codemaker_loop_hard
    old_guess = @ai.guess
    until @match_won
      sleep(1)
      break if @ai.guess_count == @max_turns

      new_guess = @ai.guess(@code.feedback(old_guess))
      @match_won = true if @code.solved?(new_guess)
      old_guess = new_guess
    end
  end

  def codemaker_loop_easy
    until @match_won
      sleep(1)
      break if @ai.guess_count == @max_turns

      guess = @ai.generate
      @match_won = true if @code.solved?(guess)
    end
  end
end

# Responsible for interactions with the human player
class Player
  attr_accessor :guess_count

  def initialize
    @guess_count = 0
  end

  def guess(settings)
    @guess_count += 1
    code_length = settings[:code_length]
    this_guess = gets.chomp
    unless valid?(this_guess, settings)
      puts "guess must be #{code_length} numbers with value less than 6"
      puts 'duplicates are disabled' unless settings[:duplicates]
      @guess_count -= 1
      this_guess = guess(settings)
    end
    this_guess
  end

  private

  def valid?(guess, settings)
    return false unless settings[:duplicates] ||
                        guess.split('').uniq.size == guess.size

    true if guess.split('').all? { |n| /[0-5]/.match?(n) } &&
            guess.size == settings[:code_length]
  end
end

# Responsible for operations related to the secret code being guessed
class Code
  attr_accessor :secret

  def initialize(code_length, duplicates)
    @code_length = code_length
    @duplicates = duplicates
    @secret = generate
  end

  def generate
    secret = []
    until secret.size == @code_length
      n = rand(6)
      if @duplicates
        secret.push(n)
        next
      end
      secret.push(n) unless secret.include?(n)
    end
    secret
  end

  def solved?(guess)
    true if guess == @secret
  end

  def feedback(guess)
    guess_copy = guess.map { |x| x }
    secret_copy = @secret.map { |x| x }
    location_matches = location_matches(guess_copy, secret_copy)
    number_matches = number_matches(guess_copy, secret_copy)
    puts "Numbers in code and in right location: \ #{location_matches}"
    puts "Numbers in code but in wrong location: \ #{number_matches}"
    [location_matches, number_matches]
  end

  private

  def location_matches(guess_copy, secret_copy)
    right_number_and_location = 0
    guess_copy.each_with_index do |digit, index|
      next unless digit == secret_copy[index]

      right_number_and_location += 1
      guess_copy[index] = 8
      secret_copy[index] = 7
    end
    right_number_and_location
  end

  def number_matches(guess_copy, secret_copy)
    right_number_wrong_location = 0
    guess_copy.each do |digit|
      next unless secret_copy.include?(digit)

      right_number_wrong_location += 1
      guess_copy[guess_copy.find_index(digit)] = 8
      secret_copy[secret_copy.find_index(digit)] = 7
    end
    right_number_wrong_location
  end
end

# Responsible for actions of the computer "player"
class Ai < Code
  attr_accessor :guess_count

  def initialize(settings)
    @code_length = settings[:code_length]
    @guess_count = 0
    @set = create_set
    @previous_guess = [1, 1, 2, 2]
    @duplicates = settings[:duplicates]
  end

  def guess(*feedback)
    @guess_count += 1
    if @guess_count == 1
      p "Ai is guessing #{@previous_guess.join}"
      return @previous_guess
    end
    narrow_set(feedback.first, @previous_guess)
    @previous_guess = @set.first
    p "Ai is guessing #{@previous_guess.join}"
    @previous_guess
  end

  def generate
    @guess_count += 1
    guess = super
    p "Ai is guessing #{guess.join}"
  end

  def narrow_set(feedback, previous_guess)
    @set.delete_if do |possible_code|
      evaluate_code(possible_code, previous_guess) != feedback
    end
  end

  def evaluate_code(possible_code, previous_guess)
    possible_code_copy = possible_code.map { |x| x }
    previous_guess_copy = previous_guess.map { |x| x }
    [
      location_matches(possible_code_copy, previous_guess_copy),
      number_matches(possible_code_copy, previous_guess_copy)
    ]
  end

  def create_set
    set = []
    upper_bound = create_upper_bound
    (0..upper_bound).each do |num|
      split_array = num.to_s.split('').map(&:to_i)
      next if split_array.any? { |x| x > 5 }

      split_array.unshift(0) until split_array.size == @code_length
      set.push(split_array)
    end
    set
  end

  def create_upper_bound
    upper_bound_array = []
    upper_bound_array.push(5) until upper_bound_array.size == @code_length
    upper_bound_array.join.to_i
  end
end

# Responsible for operation of the overarching game being played
class Game
  def initialize
    @player_won = 0
    @ai_won = 0
    @round_counter = 0
    @settings = {
      max_turns: 12,
      code_length: 4,
      duplicates: true,
      rounds: 4,
      intelligent_ai: true
    }
  end

  def play
    game_loop
    if @player_won == @ai_won
      puts "\n Tie game"
    elsif @player_won > @ai_won
      puts "\n Conratulations!! You won the game!"
    else
      puts "\n Skynet's world domination has begun! Game over! You lose!"
    end
  end

  def edit_settings
    @settings.each do |name, value|
      puts "#{name} is set to #{value}, would you like to change it? y/n"
      next unless gets.chomp == 'y'

      handle_settings_selection(name)
    end
  end

  private

  def game_loop
    until @round_counter == @settings[:rounds] || game_over
      match = Match.new(@settings)
      @round_counter += 1
      puts "Round #{@round_counter}"
      if @round_counter.odd?
        @player_won += match.play_codebreaker
      else
        @ai_won += match.play_codemaker
      end
    end
  end

  def handle_settings_selection(name)
    case name
    when :duplicates, :intelligent_ai
      switch_setting(name)
    when :rounds
      change_number_of_rounds(gets.chomp.to_i)
    else
      puts 'please enter new value'
      @settings[name] = gets.chomp.to_i
    end
  end

  def change_number_of_rounds(number_of_rounds)
    puts 'Number of rounds must be even'
    if number_of_rounds.even?
      @settings[:rounds] = number_of_rounds
    else
      change_number_of_rounds(gets.chomp.to_i)
    end
  end

  def switch_setting(setting)
    if @settings[setting]
      puts "#{setting} disabled"
      @settings[setting] = false
    else
      puts "#{setting} enabled"
      @settings[setting] = true
    end
  end

  def game_over
    rounds = @settings[:rounds]
    true if @player_won > (rounds / 2) || @ai_won > (rounds / 2)
  end
end

quit = false

until quit
  puts "\n Welcome to Mastermind! Hit 'Enter' to start, 'i' for " \
  "instructions, 's' to change settings, or type 'quit' to end\n"
  game = Game.new
  case gets.chomp
  when 'quit'
    puts 'Exiting game'
    quit = true
    next
  when 'i'
    puts INSTRUCTIONS
    next
  when 's'
    game.edit_settings
  end
  game.play
  puts "\n New game starting"
  sleep(2)
end
