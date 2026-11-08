
require 'gosu'

module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

WIN_WIDTH = 1200
WIN_HEIGHT = 900

class GameWindow < Gosu::Window

class Player
  attr_accessor :name, :positions, :ovr

  def initialize(name, positions, ovr)
    @name = name
    @positions = positions
    @ovr = ovr
  end
end

class Club
  attr_accessor :name, :players

  def initialize(name, players)
    @name = name
    @players = players
  end
end

  def initialize()
    super(WIN_WIDTH, WIN_HEIGHT, resizable: true)
    self.caption = "DRAFTIFY"

    @logo = Gosu::Image.new("media/draftify_logo.png")

    @font = Gosu::Font.new(36, name: "fonts/Baloo2-ExtraBold.ttf")
    @button_font = Gosu::Font.new(42, name: "fonts/Baloo2-ExtraBold.ttf")
    @title_font = Gosu::Font.new(55, name: "fonts/Baloo2-ExtraBold.ttf")
    @formation_font = Gosu::Font.new(52, name: "fonts/Baloo2-ExtraBold.ttf")
    @draft_font = Gosu::Font.new(18, name: "fonts/Baloo2-ExtraBold.ttf")

    @screen = :splash

    @formations = ["4-3-3", "4-2-3-1", "4-4-2"]
    @selected_formation = nil

    @club_data = read_clubs()
    puts "Loaded #{@club_data.length} lines from clubs.txt"

    @clubs = build_clubs(@club_data)
    load_club_logos()
    puts "Loaded #{@club_logos.length} club logos"

    @formation_positions = {
      "4-3-3" => [
        "LW", "ST", "RW",
        "CM", "CM", "CM",
        "LB", "CB", "CB", "RB",
        "GK"
      ],
      "4-2-3-1" => [
        "ST",
        "LW", "CAM", "RW",
        "CDM", "CDM",
        "LB", "CB", "CB", "RB",
        "GK"
      ],
      "4-4-2" => [
        "ST", "ST",
        "LM", "CM", "CM", "RM",
        "LB", "CB", "CB", "RB",
        "GK"
      ]
    }


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
    
    if @spinning_club
      current_time = Gosu.milliseconds
      interval = 70 + @club_spin_steps * 8

      if current_time - @last_club_spin_time >= interval
        @club_spin_index = (@club_spin_index + 1) % @clubs.length
        @club_spin_steps += 1
        @last_club_spin_time = current_time

        if @club_spin_steps >= @clubs.length
          @spinning_club = false
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
  
  def start_club_spin()
    @spinning_club = true
    @club_spin_index = @clubs.index(@current_club)
    @club_spin_steps = 0
    @last_club_spin_time = Gosu.milliseconds
  end

  def draw()
    case @screen
    when :splash
      draw_splash_screen()
    when :menu
      draw_menu()
    when :formation
      draw_formation()
    when :pitch
      draw_pitch()
     when :draft
      draw_draft()
    when :result
      draw_result()
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

    # Spin or Continue button
      button_width = 340
      button_height = 65
      button_x = (width - button_width) / 2
      button_y = height * 0.78

      if @selected_formation == nil
        if !@spinning
          draw_button("SPIN", button_x, button_y, button_width, button_height)
        end
      else
        draw_button("CONTINUE", button_x, button_y, button_width, button_height)
      end
    end
  
  
  
  def draw_positions(pitch_x, pitch_y, pitch_width, pitch_height)
    positions = @formation_positions[@selected_formation]
    @slot_positions = []

    if @selected_formation == "4-3-3"
      rows = [3, 3, 4, 1]
    elsif @selected_formation == "4-2-3-1"
      rows = [1, 3, 2, 4, 1]
    else
      rows = [2, 4, 4, 1]
    end

    index = 0
    row = 0

    while row < rows.length
      players_in_row = rows[row]
      column = 0

      while column < players_in_row
        position = positions[index]

        x = pitch_x + pitch_width * (column + 1) / (players_in_row + 1)
        y = pitch_y + pitch_height * (row + 1) / (rows.length + 1)
        @slot_positions << [x, y]
       
        # Get the player in this slot
        player = nil

        if @squad != nil
          player = @squad[index]
        end

        # Draw black circle border
        draw_rounded_button(
          x - 37, y - 37,
          74, 74,
          Gosu::Color::BLACK,
          ZOrder::MIDDLE
        )

        # Check if the slot contains a player
        if player != nil
          circle_color = Gosu::Color.rgb(255, 210, 60)
          display_text = player.ovr.to_s
        else
          circle_color = Gosu::Color::WHITE
          display_text = position
        end

        # Draw the circle
        draw_rounded_button(
          x - 35, y - 35,
          70, 70,
          circle_color,
          ZOrder::MIDDLE
        )

        # Centre the text inside the circle
        text_x = x - @font.text_width(display_text) / 2
        text_y = y - @font.height / 2

        @font.draw_text(
          display_text, text_x, text_y,
          ZOrder::TOP, 1.0, 1.0,
          Gosu::Color::BLACK
        )

        # Display the player's name below the circle
        if player != nil
          name_width = @draft_font.text_width(player.name)
          name_scale = 1.0

          if name_width > 130
            name_scale = 130.0 / name_width
          end

          name_x = x - name_width * name_scale / 2
          name_y = y + 38

          @draft_font.draw_text(
            player.name, name_x, name_y,
            ZOrder::TOP, name_scale, name_scale,
            Gosu::Color::WHITE
          )
        end


        index += 1
        column += 1
      end

      row += 1
    end
  end

  def draw_pitch()
    # Background
    Gosu.draw_rect(
      0, 0, width, height,
      Gosu::Color.rgb(245, 245, 245),
      ZOrder::BACKGROUND
    )

    # Football pitch
    pitch_width = width * 0.66
    pitch_height = height * 0.75
    pitch_x = width * 0.03
    pitch_y = height * 0.15

    Gosu.draw_rect(
      pitch_x, pitch_y,
      pitch_width, pitch_height,
      Gosu::Color.rgb(70, 160, 95),
      ZOrder::MIDDLE
    )
    # White pitch border
    Gosu.draw_rect(
      pitch_x + 10, pitch_y + 10,
      pitch_width - 20, 4,
      Gosu::Color::WHITE,
      ZOrder::TOP
    )

    Gosu.draw_rect(
      pitch_x + 10, pitch_y + pitch_height - 14,
      pitch_width - 20, 4,
      Gosu::Color::WHITE,
      ZOrder::TOP
    )

    Gosu.draw_rect(
      pitch_x + 10, pitch_y + 10,
      4, pitch_height - 20,
      Gosu::Color::WHITE,
      ZOrder::TOP
    )

    Gosu.draw_rect(
      pitch_x + pitch_width - 14, pitch_y + 10,
      4, pitch_height - 20,
      Gosu::Color::WHITE,
      ZOrder::TOP
    )
    
    draw_positions(pitch_x, pitch_y, pitch_width, pitch_height)
  end

  def draw_draft()
    draw_pitch()
    display_club = @current_club

    if @spinning_club
      display_club = @clubs[@club_spin_index]
    end

    panel_x = width * 0.73
    panel_y = height * 0.12
    panel_width = width * 0.24
    panel_height = height * 0.78

    # Draw player selection panel
    Gosu.draw_rect(
      panel_x, panel_y,
      panel_width, panel_height,
      Gosu::Color::WHITE,
      ZOrder::MIDDLE
    )

    # Display draft round
    title = "ROUND #{@draft_round} / 11"
    @draft_font.draw_text(
      title, panel_x + 15, panel_y + 15,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )

    
    # Display large club logo
    club_logo = @club_logos[display_club.name]

    if club_logo != nil
      logo_scale = [80.0 / club_logo.width, 80.0 / club_logo.height].min
      logo_x = panel_x + (panel_width - club_logo.width * logo_scale) / 2

      club_logo.draw(
        logo_x, panel_y + 40,
        ZOrder::TOP, logo_scale, logo_scale
      )
    end

    # Display club name
    club_name = display_club.name
    name_scale = [1.0, (panel_width - 20.0) / @draft_font.text_width(club_name)].min
    name_x = panel_x + (panel_width - @draft_font.text_width(club_name) * name_scale) / 2

    @draft_font.draw_text(
      club_name, name_x, panel_y + 125,
      ZOrder::TOP, name_scale, name_scale,
      Gosu::Color::BLACK
    )


    if @spinning_club
      @draft_font.draw_text(
        "SPINNING...",
        panel_x + 15, panel_y + 160,
        ZOrder::TOP, 1.0, 1.0,
        Gosu::Color::BLACK
      )
      return
    end

    # Display players
      players = @eligible_players
      index = @scroll_offset

      while index < players.length && index < @scroll_offset + 12
        player = players[index]

      player_x = panel_x + 12
      player_y = panel_y + 165 + (index - @scroll_offset) * 44

      if player == @selected_player
        player_color = Gosu::Color.rgb(255, 210, 60)
      else
        player_color = Gosu::Color.rgb(240, 240, 240)
      end

      Gosu.draw_rect(
        player_x, player_y,
        panel_width - 24, 42,
        player_color,
        ZOrder::MIDDLE
      )


      @draft_font.draw_text(
        player.name,
        player_x + 8, player_y,
        ZOrder::TOP, 1.0, 1.0,
        Gosu::Color::BLACK
      )

      details = "#{player.positions.join(' / ')} | OVR #{player.ovr}"

      @draft_font.draw_text(
        details,
        player_x + 8, player_y + 20,
        ZOrder::TOP, 1.0, 1.0,
        Gosu::Color::BLACK
      )

      index += 1
    end

    # Display player count
    start_number = @scroll_offset + 1
    end_number = [@scroll_offset + 12, players.length].min

    count_text = "Players #{start_number}-#{end_number} / #{players.length}"

    @draft_font.draw_text(
      count_text,
      panel_x + 15, panel_y + panel_height - 35,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )
  end

  def draw_result()
    draw_pitch()

    panel_x = width * 0.73
    panel_y = height * 0.20
    panel_width = width * 0.24
    panel_height = height * 0.55

    Gosu.draw_rect(
      panel_x, panel_y,
      panel_width, panel_height,
      Gosu::Color::WHITE,
      ZOrder::MIDDLE
    )

    @draft_font.draw_text(
      "DRAFT COMPLETE!",
      panel_x + 20, panel_y + 30,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )

    @draft_font.draw_text(
      "TEAM OVR",
      panel_x + 20, panel_y + 110,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )

    @title_font.draw_text(
      @team_ovr.to_s,
      panel_x + 20, panel_y + 145,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )

    @draft_font.draw_text(
      "SQUAD RANK",
      panel_x + 20, panel_y + 245,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )

    if @team_rank == "LEGENDARY"
      rank_color = Gosu::Color.rgb(170, 70, 220)
    elsif @team_rank == "GOLD"
      rank_color = Gosu::Color.rgb(255, 185, 0)
    elsif @team_rank == "SILVER"
      rank_color = Gosu::Color.rgb(140, 140, 140)
    else
      rank_color = Gosu::Color.rgb(180, 100, 50)
    end

    @font.draw_text(
      @team_rank,
      panel_x + 20, panel_y + 280,
      ZOrder::TOP, 0.65, 0.65,
      rank_color
    )

    @draft_font.draw_text(
      "11 / 11 PLAYERS",
      panel_x + 20, panel_y + 390,
      ZOrder::TOP, 1.0, 1.0,
      Gosu::Color::BLACK
    )
    # Result screen buttons
    button_width = panel_width - 20
    button_height = 55
    button_x = panel_x + 10
    button_y = height * 0.76

    draw_button("RESTART", button_x, button_y, button_width, button_height)
    draw_button("MAIN MENU", button_x, button_y + 65, button_width, button_height)
    draw_button("EXIT", button_x, button_y + 130, button_width, button_height)
  end

  def button_down(id)
    return if @screen == :draft && @spinning_club
    # Scroll through the player list
    if @screen == :draft && id == Gosu::MsWheelDown
      if @scroll_offset + 12 < @eligible_players.length
        @scroll_offset += 1
      end

    elsif @screen == :draft && id == Gosu::MsWheelUp
      if @scroll_offset > 0
        @scroll_offset -= 1
      end
    end

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

        if @selected_formation != nil
          if mouse_over_button?(button_x, button_y, button_width, button_height)
            @draft_round = 1
            @squad = Array.new(11)

            @current_club = random_eligible_club()
            @eligible_players = filter_players(@current_club)
            start_club_spin()

            @selected_player = nil
            @placed_this_round = false
            @scroll_offset = 0
            @screen = :draft
          end

        elsif !@spinning
          if mouse_over_button?(button_x, button_y, button_width, button_height)
            start_spin()
          end
        end

      when :draft
        panel_x = width * 0.73
        panel_y = height * 0.12
        panel_width = width * 0.24

        player_x = panel_x + 12
        first_player_y = panel_y + 110

        if mouse_x >= player_x &&
          mouse_x <= player_x + panel_width - 24 &&
          mouse_y >= first_player_y &&
          mouse_y < first_player_y + 12 * 44

          row = ((mouse_y - first_player_y) / 44).to_i
          index = @scroll_offset + row

          if index < @eligible_players.length && !@placed_this_round
            @selected_player = @eligible_players[index]
            puts "Selected: #{@selected_player.name}"
          end
        end

        # Place the selected player on the pitch
        if @selected_player != nil && !@placed_this_round
          slot_index = 0

          while slot_index < @slot_positions.length
            slot_x = @slot_positions[slot_index][0]
            slot_y = @slot_positions[slot_index][1]

            slot_position = @formation_positions[@selected_formation][slot_index]

            if mouse_x >= slot_x - 35 &&
              mouse_x <= slot_x + 35 &&
              mouse_y >= slot_y - 35 &&
              mouse_y <= slot_y + 35 &&
              @selected_player.positions.include?(slot_position) &&
              @squad[slot_index] == nil

              @squad[slot_index] = @selected_player
              @placed_this_round = true

              puts "Placed #{@selected_player.name} at #{slot_position}"

              @selected_player = nil

              # Move to the next draft round
              if @draft_round < 11
                @draft_round += 1

                @current_club = random_eligible_club()

                if @current_club != nil
                  @eligible_players = filter_players(@current_club)
                  @scroll_offset = 0
                  start_club_spin()
                  @placed_this_round = false
                else
                  puts "No eligible clubs available"
                  @screen = :pitch
                end
              else
                @team_ovr = calculate_team_ovr()

                if @team_ovr >= 85
                  @team_rank = "LEGENDARY"
                elsif @team_ovr >= 80
                  @team_rank = "GOLD"
                elsif @team_ovr >= 75
                  @team_rank = "SILVER"
                else
                  @team_rank = "BRONZE"
                end

                puts "Draft complete!"
                puts "Team OVR: #{@team_ovr}"
                puts "Team Rank: #{@team_rank}"

                @screen = :result
              end

              break

            end

            slot_index += 1
          end
        end

      when :result
        handle_result_click()
      end 
    end
  end

  def read_clubs()
    file = File.open("clubs.txt", "r")
    lines = file.readlines
    file.close

    return lines
  end
  
  def build_clubs(lines)
    clubs = []
    line_index = 0

    while line_index < lines.length
      club_name = lines[line_index].strip
      player_count = lines[line_index + 1].to_i
      line_index += 2

      players = []
      player_index = 0

      while player_index < player_count
        name, positions_text, ovr = lines[line_index].strip.split(",")
        positions = positions_text.split("|")

        player = Player.new(name, positions, ovr.to_i)
        players << player

        line_index += 1
        player_index += 1
      end

      club = Club.new(club_name, players)
      clubs << club
    end

    return clubs
  end

  def load_club_logos()
    @club_logos = {}
    index = 0

    while index < @clubs.length
      club = @clubs[index]

      file_name = club.name.downcase.gsub(" ", "_")
      path = "media/club_logos/#{file_name}.png"

      if File.exist?(path)
        @club_logos[club.name] = Gosu::Image.new(path)
      end

      index += 1
    end
  end

  def calculate_team_ovr()
    total_ovr = 0
    player_count = 0
    index = 0

    while index < @squad.length
      player = @squad[index]

      if player != nil
        total_ovr += player.ovr
        player_count += 1
      end

      index += 1
    end

    if player_count > 0
      return total_ovr / player_count
    else
      return 0
    end
  end

  def filter_players(club)
    eligible = []
    positions = @formation_positions[@selected_formation]

    player_index = 0

    while player_index < club.players.length
      player = club.players[player_index]
      position_index = 0
      suitable = false

      while position_index < positions.length
        if player.positions.include?(positions[position_index]) &&
          @squad[position_index] == nil
          suitable = true
        end

        position_index += 1
      end

      if suitable && !@squad.include?(player)
        eligible << player
      end

      player_index += 1
    end

    return eligible.sort_by { |player| -player.ovr }
  end

  def random_eligible_club()
    available_clubs = []
    index = 0

    while index < @clubs.length
      club = @clubs[index]

      if filter_players(club).length > 0
        available_clubs << club
      end

      index += 1
    end

    return available_clubs.sample
  end

  def needs_cursor?
    return true
  end
  
  def reset_game()
    @selected_formation = nil
    @highlight_index = nil
    @spinning = false

    @draft_round = 1
    @squad = Array.new(11)
    @current_club = nil
    @eligible_players = []
    @selected_player = nil
    @placed_this_round = false
    @scroll_offset = 0

    @team_ovr = nil
    @team_rank = nil
    @slot_positions = []
  end

  def handle_result_click()
    panel_x = width * 0.73
    panel_width = width * 0.24

    button_width = panel_width - 20
    button_height = 55
    button_x = panel_x + 10
    button_y = height * 0.76

    if mouse_over_button?(button_x, button_y, button_width, button_height)
      reset_game()
      @screen = :formation

    elsif mouse_over_button?(button_x, button_y + 65, button_width, button_height)
      reset_game()
      @screen = :menu

    elsif mouse_over_button?(button_x, button_y + 130, button_width, button_height)
      close
    end
  end

  def random_formation()
    index = rand(@formations.length)
    @selected_formation = @formations[index]
  end

end

window = GameWindow.new()
window.show()
