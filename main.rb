
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

    @font = Gosu::Font.new(36, name: "fonts/Baloo2-ExtraBold.ttf")
    @button_font = Gosu::Font.new(42, name: "fonts/Baloo2-ExtraBold.ttf")
    @title_font = Gosu::Font.new(55, name: "fonts/Baloo2-ExtraBold.ttf")
    @formation_font = Gosu::Font.new(52, name: "fonts/Baloo2-ExtraBold.ttf")

    @screen = :splash

    @formations = ["4-3-3", "4-2-3-1", "4-4-2"]
    @selected_formation = nil

    @spinning = false
    @highlight_index = nil
    @spin_steps = 0
    @last_spin_time = 0
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

  
  def update()
    if @spinning
      current_time = Gosu.milliseconds
      interval = 100 + @spin_steps * 15

      if current_time - @last_spin_time >= interval
        @highlight_index = (@highlight_index + 1) % @formations.length
        @spin_steps += 1
        @last_spin_time = current_time

        if @spin_steps >= 18
          @spinning = false
          @selected_formation = @formations[@highlight_index]
        end
      end
    end
  end
  
  def start_spin()
    return if @spinning

    @spinning = true
    @selected_formation = nil
    @highlight_index = rand(@formations.length)
    @spin_steps = 0
    @last_spin_time = Gosu.milliseconds
  end
  
  def draw()
    case @screen
    when :splash
      draw_splash_screen()
    when :menu
      draw_menu()
    when :formation
      draw_formation()
    end
  end

  def mouse_over_button?(x, y, width, height)
  mouse_x >= x && mouse_x <= x + width &&
    mouse_y >= y && mouse_y <= y + height
  end
  
  def draw_rounded_button(x, y, button_width, button_height, color, z)
    radius = button_height / 2.0

    # Middle rectangle
    Gosu.draw_rect(
      x + radius, y,
      button_width - 2 * radius, button_height,
      color, z
    )

    # Two rounded ends
    [x + radius, x + button_width - radius].each do |centre_x|
      centre_y = y + radius

      angle = 0
      while angle < 360
        a1 = angle * Math::PI / 180
        a2 = (angle + 10) * Math::PI / 180

        Gosu.draw_triangle(
          centre_x, centre_y, color,
          centre_x + Math.cos(a1) * radius,
          centre_y + Math.sin(a1) * radius, color,
          centre_x + Math.cos(a2) * radius,
          centre_y + Math.sin(a2) * radius, color,
          z
        )

        angle += 10
      end
    end
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

    # Draw pill-shaped button using rectangles and circles

    draw_rounded_button(x - 2, y - 2, button_width + 4, button_height + 4,
                        Gosu::Color.rgb(180, 180, 180), ZOrder::MIDDLE)

    draw_rounded_button(x, y, button_width, button_height,
                        button_color, ZOrder::MIDDLE)

    text_x = x + (button_width - @button_font.text_width(text)) / 2
    text_y = y + (button_height - @button_font.height) / 2

    @button_font.draw_text(
      text, text_x, text_y,
      ZOrder::TOP, 1.0, 1.0, text_color
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
  
  def draw_formation()
    # Background
    Gosu.draw_rect(
      0, 0, width, height,
      Gosu::Color.rgb(245, 245, 245),
      ZOrder::BACKGROUND
    )

    # Title
    title = "FORMATION"
    title_x = (width - @title_font.text_width(title)) / 2

    @title_font.draw_text(
      title, title_x, height * 0.20,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )

    
  # Show all formations in rounded cards
  card_width = 240
  card_height = 120
  card_gap = 30

  total_width = card_width * @formations.length + card_gap * (@formations.length - 1)
  start_x = (width - total_width) / 2
  card_y = height * 0.40

  index = 0
  while index < @formations.length
    formation_text = @formations[index]

    card_x = start_x + index * (card_width + card_gap)

    # Grey border
    draw_rounded_button(
      card_x - 2, card_y - 2,
      card_width + 4, card_height + 4,
      Gosu::Color.rgb(180, 180, 180),
      ZOrder::MIDDLE
    )

    # Highlight the current formation
    if index == @highlight_index
      card_color = Gosu::Color.rgb(255, 210, 60)
    else
      card_color = Gosu::Color::WHITE
    end

    draw_rounded_button(
      card_x, card_y,
      card_width, card_height,
      card_color,
      ZOrder::MIDDLE
    )

    # Centre the formation text
    text_x = card_x + (card_width - @formation_font.text_width(formation_text)) / 2
    text_y = card_y + (card_height - @formation_font.height) / 2

    @formation_font.draw_text(
      formation_text, text_x, text_y,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )

    index += 1
  end


    # Show the selected formation
    if @selected_formation != nil
      result = "Selected: #{@selected_formation}"
      result_x = (width - @font.text_width(result)) / 2

      @font.draw_text(
        result, result_x, height * 0.60,
        ZOrder::TOP, 1.0, 1.0,
        Gosu::Color::BLACK
      )
    end

    # Spin button
    button_width = 340
    button_height = 65
    button_x = (width - button_width) / 2
    button_y = height * 0.78

    draw_button("SPIN", button_x, button_y, button_width, button_height)
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
          @selected_formation = nil
          @screen = :formation

        elsif mouse_over_button?(button_x, exit_y, button_width, button_height)
          close
        end

      when :formation
        button_width = 340
        button_height = 65
        button_x = (width - button_width) / 2
        button_y = height * 0.78

        if mouse_over_button?(button_x, button_y, button_width, button_height)
          start_spin()
        end
      end

    end
  end

  def needs_cursor?
    return true
  end

  def random_formation()
    index = rand(@formations.length)
    @selected_formation = @formations[index]
  end

end

window = GameWindow.new()
window.show()
