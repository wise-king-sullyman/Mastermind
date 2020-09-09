class Game
  def initialize
    @game_over = false
  end

  def play
    player = Player.new
    code = Code.new
    p code.secret

    until @game_over || player.guess_count == 12
      puts "#{12 - player.guess_count} guesses remaining"
      guess = player.guess
      @game_over = true if code.solved?(guess)
    end
  end
end

class Player
  attr_accessor :name, :guess_count

  def initialize
    @guess_count = 0
  end

  def guess
    @guess_count += 1
    gets.chomp.to_i
  end
end

class Code
  attr_accessor :secret

  def initialize(code_length=4, duplicates=false, max_turns=12)
    @code_length = code_length
    @duplicates = duplicates
    @max_turns = max_turns
    @secret = generate
  end

  def generate
    secret = []
    until secret.size == @code_length
      n = (rand*10).floor
      secret.push(n) if n < 6
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