
require 'gosu'

module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

WIN_WIDTH = 900
WIN_HEIGHT = 650

class GameWindow < Gosu::Window

  def initialize()
    super(WIN_WIDTH, WIN_HEIGHT, false)
    self.caption = "DRAFTIFY"

    @logo = Gosu::Image.new("media/draftify_logo.png")
    @font = Gosu::Font.new(22)
  end

  def draw()
    Gosu.draw_rect(
      0, 0,
      WIN_WIDTH, WIN_HEIGHT,
      Gosu::Color::WHITE,
      ZOrder::BACKGROUND
    )

    @logo.draw(150, 150, ZOrder::MIDDLE, 0.6, 0.6)

    @font.draw_text(
      "Click anywhere to start",
      320, 500,
      ZOrder::TOP,
      1.0, 1.0,
      Gosu::Color::BLACK
    )
  end

  def needs_cursor?
    return true
  end

end

window = GameWindow.new()
window.show()
