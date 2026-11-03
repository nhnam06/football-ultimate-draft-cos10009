
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
    @button_font = Gosu::Font.new(26)

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

  def mouse_over_button?(x, y, width, height)
  mouse_x >= x && mouse_x <= x + width &&
    mouse_y >= y && mouse_y <= y + height
end


def draw_button(text, x, y, button_width, button_height)
  hovered = mouse_over_button?(x, y, button_width, button_height)

  if hovered
    x -= 5
    y -= 3
    button_width += 10
    button_height += 6

    button_color = Gosu::Color::BLACK
    text_color = Gosu::Color::WHITE
  else
    button_color = Gosu::Color::WHITE
    text_color = Gosu::Color::BLACK
  end

  # Button border
  Gosu.draw_rect(
    x - 2, y - 2,
    button_width + 4, button_height + 4,
    Gosu::Color.rgb(180, 180, 180),
    ZOrder::MIDDLE
  )

  # Button background
  Gosu.draw_rect(
    x, y,
    button_width, button_height,
    button_color,
    ZOrder::MIDDLE
  )

  # Centre the button text
  text_x = x + (button_width - @button_font.text_width(text)) / 2
  text_y = y + (button_height - @button_font.height) / 2

  @button_font.draw_text(
    text, text_x, text_y,
    ZOrder::TOP,
    1.0, 1.0,
    text_color
  )
end



def draw_menu()
  # Background
  Gosu.draw_rect(
    0, 0,
    width, height,
    Gosu::Color.rgb(245, 245, 245),
    ZOrder::BACKGROUND
  )

  # Large DRAFTIFY logo
  scale_x = (width * 0.85) / @logo.width
  scale_y = (height * 0.70) / @logo.height
  scale = [scale_x, scale_y].min

  logo_x = (width - @logo.width * scale) / 2
  logo_y = height * 0.03

  @logo.draw(
    logo_x, logo_y,
    ZOrder::MIDDLE,
    scale, scale
  )

  # Buttons
  button_width = 340
  button_height = 65
  button_x = (width - button_width) / 2

  start_y = height * 0.60
  exit_y = height * 0.75

  draw_button("START DRAFT", button_x, start_y, button_width, button_height)
  draw_button("EXIT", button_x, exit_y, button_width, button_height)
end

  def button_down(id)
    if id == Gosu::MsLeft

      case @screen
      when :splash
        @screen = :menu

      when :menu
        button_width = 340
        button_height = 65
        button_x = (width - button_width) / 2

        start_y = height * 0.60
        exit_y = height * 0.75

        if mouse_over_button?(button_x, start_y, button_width, button_height)
          puts "Start Draft clicked!"

        elsif mouse_over_button?(button_x, exit_y, button_width, button_height)
          close
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
