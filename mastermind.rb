# frozen_string_literal: true

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
    p @code.secret
    guess = codebreaker_loop

    if @match_won
      puts "\n \tCongratulations! #{guess.join} was the code!"
      return 1
    end

    puts "\n \tLoser! the code was #{@code.secret}"
    0
  end

  def codebreaker_loop
    until @match_won
      guesses_remaining = @max_turns - @player.guess_count
      break if guesses_remaining.zero?

      puts "\n \t#{guesses_remaining} guesses remaining"
      guess = @player.guess(@settings).split('').map(&:to_i)
      @code.codebreaker_feedback(guess)
      @match_won = true if @code.solved?(guess)
    end
    guess
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

  def codemaker_loop_hard
    old_guess = @ai.guess
    until @match_won
      break if @ai.guess_count == @max_turns

      new_guess = @ai.guess(@code.codemaker_feedback(old_guess))
      @match_won = true if @code.solved?(new_guess)
      old_guess = new_guess
    end
  end

  def codemaker_loop_easy
    until @match_won
      break if @ai.guess_count == @max_turns

      guess = @ai.generate
      @match_won = true if @code.solved?(guess)
    end
  end
end

# Responsible for interactions with the human player
class Player
  attr_accessor :name, :guess_count

  def initialize
    @guess_count = 0
  end

  def guess(settings)
    @guess_count += 1
    code_length = settings[:code_length]
    this_guess = gets.chomp
    unless valid?(this_guess, settings)
      puts "guess must be exactly #{code_length} numbers less than 6!"
      puts 'duplicates are disabled' unless settings[:duplicates]
      @guess_count -= 1
      this_guess = guess(settings)
    end
    this_guess
  end

  def valid?(guess, settings)
    return false unless settings[:duplicates] ||
                        guess.split('').uniq.size == guess.size

    true if guess.split('').all? { |n| /[0-5]/.match?(n) } &&
            guess.size == settings[:code_length]
  end
end

# Responsible for operations related to the secret code being guessed
class Code
  attr_accessor :secret, :code_length

  def initialize(code_length, duplicates)
    @code_length = code_length
    @duplicates = duplicates
    @secret = generate
  end

  def generate
    secret = []
    until secret.size == @code_length
      n = rand(5)
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

  def codebreaker_feedback(guess)
    guess_copy = []
    guess.map { |x| guess_copy.push(x) }
    secret_copy = []
    @secret.map { |x| secret_copy.push(x)}
    puts "Numbers in code and in right location: \
    #{location_matches(guess_copy, secret_copy)}"
    puts "Numbers in code but in wrong location: \
    #{number_matches(guess_copy, secret_copy)}"
  end

  def codemaker_feedback(guess)
    guess_copy = []
    guess.map { |x| guess_copy.push(x) }
    secret_copy = []
    @secret.map { |x| secret_copy.push(x)}
    [
      location_matches(guess_copy, secret_copy), 
      number_matches(guess_copy, secret_copy)
    ]
  end

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
      p "Ai is picking #{@previous_guess.join}"
      return @previous_guess
    end
    narrow_set(feedback.first, @previous_guess)
    @previous_guess = @set.first
    p "Ai is picking #{@previous_guess.join}"
    @previous_guess
  end

  def generate
    @guess_count += 1
    guess = super
    p "Ai is picking #{guess.join}"
  end

  def narrow_set(feedback, previous_guess)
    @set.delete_if { |possible_code|
      evaluate_code(possible_code, previous_guess) != feedback
    }
  end

  def evaluate_code(possible_code, previous_guess)
    guess_copy = []
    possible_code.map { |x| guess_copy.push(x) }
    previous_guess_copy = []
    previous_guess.map { |x| previous_guess_copy.push(x) }
    [
      location_matches(guess_copy, previous_guess_copy),
      number_matches(guess_copy, previous_guess_copy)
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

  def edit_settings
    @settings.each do |name, value|
      puts "#{name} is set to #{value}, would you like to change it? y/n"
      input = gets.chomp
      if input == 'y' && ( name == :duplicates || name == :intelligent_ai )
        switch_setting(name)
      elsif input == 'y'
        puts 'please enter new value'
        @settings[name] = gets.chomp.to_i
      end
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

game = Game.new
puts 'Welcome to Mastermind! Hit "Enter" to start or "s" to change settings'
game.edit_settings if gets.chomp == 's'
game.play
