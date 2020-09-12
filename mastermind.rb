class Game
  def initialize(max_turns = 12)
    @game_won = false
    @max_turns = max_turns
    @player = Player.new
    @code = Code.new
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
      @code.feedback(guess)
      @game_won = true if @code.solved?(guess)
    end
    guess
  end

  def play_codemaker
    p "Enter code"
    @code.secret = @player.guess(@code.code_length).split('').map(&:to_i)
    ai_guess = @code.generate
    until @code.solved?(ai_guess)
      ai_guess = @code.generate
    end
    p "The AI cracked the code! It was #{@code.secret}"
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

  def feedback(guess)
    code_copy = []
    @secret.map { |x| code_copy.push(x) }
    puts "Numbers in code and in right location: \
    #{location_matches(guess, code_copy)}"
    puts "Numbers in code but in wrong location: \
    #{number_matches(guess, code_copy)}"
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

class Ai
  def guess
  end
end

game = Game.new
game.play_codemaker
