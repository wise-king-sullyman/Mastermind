require 'pry'

class Match
  def initialize(settings)
    @match_won = false
    @max_turns = settings[:max_turns]
    @player = Player.new
    @code = Code.new(settings[:code_length], settings[:duplicates])
    @ai = Ai.new
  end

  def play_codebreaker
    p @code.secret
    guess = codebreaker_loop

    if @match_won
      puts "\n \tCongratulations! #{guess.join} was the code!"
      return
    end

    puts "\n \tLoser! the code was #{@code.secret}"
  end

  def codebreaker_loop
    until @match_won
      guesses_remaining = @max_turns - @player.guess_count
      break if guesses_remaining.zero?

      puts "\n \t#{guesses_remaining} guesses remaining"
      guess = @player.guess(@code.code_length).split('').map(&:to_i)
      @code.codebreaker_feedback(guess)
      @match_won = true if @code.solved?(guess)
    end
    guess
  end

  def play_codemaker
    p "Enter code"
    @code.secret = @player.guess(@code.code_length).split('').map(&:to_i)
    old_guess = @ai.guess
    until @match_won
      break if @ai.guess_count == @max_turns

      new_guess = @ai.guess(@code.codemaker_feedback(old_guess))
      @match_won = true if @code.solved?(new_guess)
      old_guess = new_guess
    end
    p "The AI cracked the code in #{@ai.guess_count} guesses! \
    It was #{@code.secret}"
  end
end

class Player
  attr_accessor :name, :guess_count

  def initialize
    @guess_count = 0
  end

  def guess(code_length)
    @guess_count += 1
    this_guess = gets.chomp
    unless /[0-5][0-5][0-5][0-5]/.match?(this_guess) && this_guess.size == 4
      puts "guess must be exactly #{code_length} numbers less than 6!"
      @guess_count -= 1
      this_guess = guess(code_length)
    end
    this_guess
  end
end

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
    [location_matches(guess_copy, secret_copy), number_matches(guess_copy, secret_copy)]
  end

  def location_matches(guess_copy, secret_copy)
    right_number_and_location = 0
    guess_copy.each_with_index do |digit, index|
      if digit == secret_copy[index]
        right_number_and_location += 1
        guess_copy[index] = 8
        secret_copy[index] = 7
      end
    end
    right_number_and_location
  end

  def number_matches(guess_copy, secret_copy)
    right_number_wrong_location = 0
    guess_copy.each do |digit|
      if secret_copy.include?(digit)
        right_number_wrong_location += 1
        guess_copy[guess_copy.find_index(digit)] = 8
        secret_copy[secret_copy.find_index(digit)] = 7
      end
    end
    right_number_wrong_location
  end
end

class Ai < Code
  attr_accessor :guess_count

  def initialize
    @guess_count = 0
    @set = create_set
    @previous_guess = [1, 1, 2, 2]
  end

  def guess(*feedback)
    @guess_count += 1
    if @guess_count == 1
      p "Ai is picking #{@previous_guess}"
      return @previous_guess
    end
    narrow_set(feedback.first, @previous_guess)
    p @previous_guess
    puts "All options eliminated" if @set.empty?
    @previous_guess = @set.first
    p "Ai is picking #{@previous_guess}"
    @previous_guess
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
    previous_guess.map { |x| previous_guess_copy.push(x)}
    [
      location_matches(guess_copy, previous_guess_copy),
      number_matches(guess_copy, previous_guess_copy)
    ]
  end

  def create_set
    set = []
    (0..5555).each do |num|
      split_array = num.to_s.split('').map(&:to_i)
      next if split_array.any? {|x| x > 5}

      if split_array.size == 4
        set.push(split_array)
        next
      end

      until split_array.size == 4
        split_array.unshift(0)
      end
      set.push(split_array)
    end
    set
  end
end

class Game
  def initialize
    @game_won = false
    @round_counter = 0
    @settings = {
      max_turns: 12,
      code_length: 4,
      duplicates: true,
      rounds: 4
    }
  end

  def play(rounds)
    until @game_won
      if @round_counter == rounds
        puts "Tie game"
        break
      end
      match = Match.new(@settings)
      @round_counter += 1
      puts "Round #{@round_counter}"
      @round_counter.odd? ? match.play_codebreaker : match.play_codemaker
    end
  end
end
puts 'Welcome to Mastermind! Hit "Enter" to start or "s" to change settings'

game = Game.new
game.play(4)