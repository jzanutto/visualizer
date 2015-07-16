# Visualizer

class Visualizer < Processing::App

  # Load minim and import the packages we'll be using
  load_library "minim"
  import "ddf.minim"
  import "ddf.minim.analysis"

    def setup
        smooth  # Make it prettier
        size 700, 200, P3D  # Let's pick a more interesting size
        background 10  # Pick a darker background color

        setup_sound
    end

    def setup_sound
        @beat_counter = 0
        # Creates a Minim object
        @minim = Minim.new(self)
        # Lets Minim grab sound data from mic/soundflower
        @input = @minim.get_line_in

        # Gets FFT values from sound data
        @fft = FFT.new(@input.left.size, 44100)
        # Our beat detector object
        @beat = BeatDetect.new

        # Set an array of frequencies we'd like to get FFT data for
        @freqs = [20, 60, 170, 310, 630, 1080, 3000, 6400, 8000, 12000, 14000, 16000]

        # Create arrays to store the current FFT values,
        #   previous FFT values, highest FFT values we've seen,
        #   and scaled/normalized FFT values (which are easier to work with)
        @current_ffts   = Array.new(@freqs.size, 0.001)
        @max_ffts       = Array.new(@freqs.size, 0.001)
        @scaled_ffts    = Array.new(@freqs.size, 0.001)

        # We'll use this value to adjust the "smoothness" factor
        #   of our sound responsiveness
        @fft_smoothing = 0.8
    end

    def draw
        background 32, 36, 45
        update_sound
        animate_sound
    end

    def animate_sound
        stroke 255
        line 0, height/2, width, height/2

        if @beat.is_onset
            @beat_counter += 1
        end
        @scaled_ffts.each_with_index do |fft, i|
            placement = width/@freqs.size * i
            # if @beat_counter % 10 == 0
                r = rand
                g = rand
                b = rand
                fill r*256, g*256, b*256, 256/6
            # end
            # rect placement+5, 0, width.fdiv(@freqs.size) - 10, @fft_bwth[i] * (height/2) % (height / 2)
            rect placement+5, height, width.fdiv(@freqs.size) - 10, -1 * fft * height
            rect placement+5, 0, width.fdiv(@freqs.size) - 10, fft * height
        end
    end

    def update_sound
        @fft.forward @input.left

        previous_ffts = @current_ffts
        @fft_bwth = []
        # Iterate over the frequencies of interest and get FFT values
        @freqs.each_with_index do |freq, i|
          # The FFT value for this frequency
          new_fft = @fft.get_freq(freq)
          new_bwth = @fft.get_band(freq)

          # Set it as the frequncy max if it's larger than the previous max
          @max_ffts[i] = new_fft if new_fft > @max_ffts[i]
          # max_bwth[i] = new_bwth if new new_bwth > 

          # Use our "smoothness" factor and the previous FFT to set a current FFT value
          @current_ffts[i] = ((1 - @fft_smoothing) * new_fft) + (@fft_smoothing * previous_ffts[i])
          # @fft_bwth[i] = ((1 - @fft_smoothing) * new_fft) + (@fft_smoothing * )

          # Set a scaled/normalized FFT value that will be easier to work with for this frequency
          @scaled_ffts[i] = (@current_ffts[i]/@max_ffts[i])
          @fft_bwth[i] = @fft.get_band(freq)
      end

        # Check if there's a beat, will be stored in @beat.is_onset
        @beat.detect(@input.left)
    end

end

Visualizer.new :title => "Visualizer"

# @scaled_ffts[i] = 0 if @scaled_ffts[i] < 1e-44