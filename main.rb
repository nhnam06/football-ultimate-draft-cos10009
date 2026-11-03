
require 'gosu'

module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

WIN_WIDTH = 1200
WIN_HEIGHT = 900

class GameWindow < Gosu::Window

  def initialize()
    super(WIN_WIDTH, WIN_HEIGHT, resizable: true)
    self.caption = "DRAFTIFY"

    @logo = Gosu::Image.new("media/draftify_logo.png")
    @font = Gosu::Font.new(22)
    @screen = :splash
  end

  
  def draw_splash_screen()
    # Draw a white background covering the whole window
    Gosu.draw_rect(
      0, 0,
      width, height,
      Gosu::Color::WHITE,
      ZOrder::BACKGROUND
    )

    # Resize the logo while keeping its original proportions
    scale_x = (width * 0.85) / @logo.width
    scale_y = (height * 0.70) / @logo.height
    scale = [scale_x, scale_y].min

    # Centre the logo
    logo_x = (width - @logo.width * scale) / 2
    logo_y = (height - @logo.height * scale) / 2

    @logo.draw(
      logo_x, logo_y,
      ZOrder::MIDDLE,
      scale, scale
    )

    # Draw the instruction text
    text = "Click anywhere to start"
    text_x = (width - @font.text_width(text)) / 2
    text_y = height * 0.8

    @font.draw_text(
      text,
      text_x, text_y,
      ZOrder::TOP,
      1.0, 1.0,
      Gosu::Color::BLACK
    )
  end

  def draw()
    case @screen
    when :splash
      draw_splash_screen()
    when :menu
      draw_menu()
    end
  end

  def draw_menu()
  Gosu.draw_rect(
    0, 0,
    width, height,
    Gosu::Color::WHITE,
    ZOrder::BACKGROUND
  )

  title = "DRAFTIFY"
  title_x = (width - @font.text_width(title)) / 2

  @font.draw_text(
    title, title_x, height * 0.2,
    ZOrder::TOP,
    2.0, 2.0,
    Gosu::Color::BLACK
  )

  # Start Draft button
  Gosu.draw_rect(
    width / 2 - 150, height * 0.45,
    300, 60,
    Gosu::Color::BLACK,
    ZOrder::MIDDLE
  )

  # Exit button
  Gosu.draw_rect(
    width / 2 - 150, height * 0.60,
    300, 60,
    Gosu::Color::BLACK,
    ZOrder::MIDDLE
  )

  @font.draw_text(
    "START DRAFT",
    width / 2 - 75, height * 0.45 + 18,
    ZOrder::TOP,
    1.0, 1.0,
    Gosu::Color::WHITE
  )

  @font.draw_text(
    "EXIT",
    width / 2 - 22, height * 0.60 + 18,
    ZOrder::TOP,
    1.0, 1.0,
    Gosu::Color::WHITE
  )
  end

  def button_down(id)
    if id == Gosu::MsLeft

      case @screen
      when :splash
        @screen = :menu

      when :menu
        button_x = width / 2 - 150

        if mouse_x >= button_x && mouse_x <= button_x + 300

          if mouse_y >= height * 0.45 && mouse_y <= height * 0.45 + 60
            puts "Start Draft clicked!"

          elsif mouse_y >= height * 0.60 && mouse_y <= height * 0.60 + 60
            close
          end

        end
      end

    end
  end

  def needs_cursor?
    return true
  end

end

window = GameWindow.new()
window.show()
