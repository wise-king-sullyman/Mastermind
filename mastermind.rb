class Game
  def initialize(max_turns = 12)
    @game_won = false
    @max_turns = max_turns
  end

  def play
    player = Player.new
    code = Code.new
    p code.secret

    until @game_won
      guesses_remaining = @max_turns - player.guess_count
      break if guesses_remaining.zero?

      puts "#{guesses_remaining} guesses remaining"
      guess = player.guess
      @game_won = true if code.solved?(guess)
    end

    if @game_won
      puts "Congratulations! #{guess.join} was the code!"
      return
    end

    puts "Loser!"
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

  def initialize(code_length = 4, duplicates = false)
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

  def feedback
  end
end

game = Game.new
game.play
