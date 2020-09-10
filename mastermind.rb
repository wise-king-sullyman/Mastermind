class Game
  def initialize(max_turns = 12)
    @game_won = false
    @max_turns = max_turns
    @player = Player.new
    @code = Code.new
  end

  def play
    p @code.secret
    guess = game_loop

    if @game_won
      puts "Congratulations! #{guess.join} was the code!"
      return
    end

    puts "Loser!"
  end

  def game_loop
    until @game_won
      guesses_remaining = @max_turns - @player.guess_count
      break if guesses_remaining.zero?

      puts "#{guesses_remaining} guesses remaining"
      guess = @player.guess
      @code.feedback(guess)
      @game_won = true if @code.solved?(guess)
    end
    guess
  end
end

class Player
  attr_accessor :name, :guess_count

  def initialize
    @guess_count = 0
  end

  def guess
    @guess_count += 1
    gets.chomp.split('').map { |digit| digit.to_i }
  end
end

class Code
  attr_accessor :secret

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
    puts "#{location_matches(guess, code_copy)} location matches"
    puts "#{number_matches(guess, code_copy)} digit matches"
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

game = Game.new
game.play
