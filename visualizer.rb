# Visualizer

class Visualizer < Processing::App

  # Load minim and import the packages we'll be using
  load_library "minim"
  import "ddf.minim"
  import "ddf.minim.analysis"

  def setup
    smooth  # Make it prettier
    size 700, 200, P2D  # Let's pick a more interesting size
    setup_sound
  end

  def setup_sound
    @beat_counter = 0
    # Creates a Minim object
    minim = Minim.new self
    # Lets Minim grab sound data from mic/soundflower
    @input = minim.get_line_in

    # Gets FFT values from sound data
    # Our beat detector object
    @beat = BeatDetect.new

    # Set an array of frequencies we'd like to get FFT data for
    @freqs = [20, 60, 170, 310, 630, 1080, 3000, 6400, 8000, 12000, 14000, 16000]

    # preallocate lists to be small (so we render them) when nothing's playing
    [:left, :right].each do |side|
      # note that we want stereo values, so we create everything with left and right
      instance_variable_set "@fft_#{side.to_s}", FFT.new(@input.send(side).size, 44100)
      instance_variable_set "@current_ffts_#{side.to_s}", Array.new(@freqs.size, 0.001)
      instance_variable_set "@max_ffts_#{side.to_s}", Array.new(@freqs.size, 0.001)
      instance_variable_set "@scaled_ffts_#{side.to_s}", Array.new(@freqs.size, 0.001)
    end
    # frequency smoothener alpha value to reduce sporadic rendering
    @fft_smoothing = 0.87
  end

  def draw
    background 32, 36, 45, 0.2
    update_sound
    animate_sound
  end

  def animate_sound
    stroke 255
    line 0, height/2, width, height/2

    if @beat.is_onset
      @beat_counter += 1
    end
    [:left, :right].each do |side|
      fft = instance_variable_get "@scaled_ffts_#{side.to_s}"
      fft.each_with_index do |fft, i|
        placement = width/@freqs.size * i
        r = rand * 256
        g = rand * 256
        b = rand * 256
        fill r, g, b, 256/7
        if side == :left
          draw_rect placement + 5, height, width.fdiv(@freqs.size) - 10, -1 * fft * height
          # rect placement+5, height, width.fdiv(@freqs.size) - 10, -1 * fft * height
        else
          draw_rect placement + 5, 0, width.fdiv(@freqs.size) - 10, fft * height
        end
      end
    end
  end

  # helper so we can leverage 3D mode
  def draw_rect(x, y, width, height)
    rect x, y, width, height
  end

  def update_sound
    [:left, :right].each do |side|
      fft = instance_variable_get("@fft_#{side.to_s}")
      input_signal = @input.send(side)
      fft.forward input_signal

      previous_ffts = instance_variable_get "@current_ffts_#{side.to_s}"
      max_ffts = instance_variable_get "@max_ffts_#{side.to_s}"
      current_ffts = instance_variable_get "@current_ffts_#{side.to_s}"
      # Iterate over the frequencies of interest and get FFT values
      @freqs.each_with_index do |freq, i|
        # The FFT value for this frequency
        new_fft = fft.get_freq(freq)

        # Set it as the frequncy max if it's larger than the previous max
        max_ffts[i] = new_fft if new_fft > max_ffts[i]

        # Use our "smoothness" factor and the previous FFT to set a current FFT value
        current_ffts[i] = ((1 - @fft_smoothing) * new_fft) + (@fft_smoothing * previous_ffts[i])

        # Set a scaled/normalized FFT value that will be easier to work with for this frequency
        instance_variable_get("@scaled_ffts_#{side.to_s}")[i] = (current_ffts[i]/max_ffts[i])
      end

          # Check if there's a beat, will be stored in @beat.is_onset
      @beat.detect(input_signal)
    end
  end

end

Visualizer.new :title => "Visualizer"
