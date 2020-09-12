require 'pry'

class Game
  def initialize(max_turns = 12)
    @game_won = false
    @max_turns = max_turns
    @player = Player.new
    @code = Code.new
    @ai = Ai.new
  end

  def play_codebreaker
    p @code.secret
    guess = codebreaker_loop

    if @game_won
      puts "\n \tCongratulations! #{guess.join} was the code!"
      return
    end

    puts "\n \tLoser! the code was #{@code.secret}"
  end

  def codebreaker_loop
    until @game_won
      guesses_remaining = @max_turns - @player.guess_count
      break if guesses_remaining.zero?

      puts "\n \t#{guesses_remaining} guesses remaining"
      guess = @player.guess(@code.code_length).split('').map(&:to_i)
      @code.codebreaker_feedback(guess)
      @game_won = true if @code.solved?(guess)
    end
    guess
  end

  def play_codemaker
    p "Enter code"
    @code.secret = @player.guess(@code.code_length).split('').map(&:to_i)
    old_guess = @ai.guess
    until @game_won
      break if @ai.guess_count == @max_turns

      new_guess = @ai.guess(@code.codemaker_feedback(old_guess))
      @game_won = true if @code.solved?(new_guess)
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

  def initialize(code_length = 4, duplicates = true)
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
    code_copy = []
    @secret.map { |x| code_copy.push(x) }
    puts "Numbers in code and in right location: \
    #{location_matches(guess, code_copy)}"
    puts "Numbers in code but in wrong location: \
    #{number_matches(guess, code_copy)}"
  end

  def codemaker_feedback(guess)
    code_copy = []
    @secret.map { |x| code_copy.push(x) }
    [location_matches(guess, code_copy),number_matches(guess, code_copy)]
  end

  def location_matches(guess, code_copy)
    right_number_and_location = 0
    guess.each_with_index do |digit, index|
      if digit == code_copy[index]
        right_number_and_location += 1
        code_copy[index] = 7
      end
    end
    right_number_and_location
  end

  def number_matches(guess, code_copy)
    right_number_wrong_location = 0
    guess.each do |digit|
      if code_copy.include?(digit)
        right_number_wrong_location += 1
        code_copy[code_copy.find_index(digit)] = 7
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
    return @previous_guess if @guess_count == 1

    narrow_set(feedback.first, @previous_guess)
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
    code_copy = []
    possible_code.map { |x| code_copy.push(x) }
    [
      location_matches(previous_guess, code_copy),
      number_matches(previous_guess, code_copy)
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

game = Game.new
puts "Enter 1 for codebreaker, or 2 for codemaker"
gets.chomp.to_i == 1 ? game.play_codebreaker : game.play_codemaker
