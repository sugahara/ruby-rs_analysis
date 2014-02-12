require 'gsl'
require 'rs_analysis/approximate/least_square'
require 'rs_analysis/error'
require 'rs_analysis/array'
module RSAnalysis
  class Base
  include Approximate
    attr_accessor :log_rs_statistics, :hurst_mean, :hurst_max, :hurst_min
    DEFAULT_OPTS = {
      :k_max => 100,
      :k_min => 2,
      :sample_size => 50,
      :use_delta_n => true
    }
    RS_INDEX = 0
    RS_MEAN_INDEX = 1
    RS_MAX_INDEX = 2
    RS_MIN_INDEX = 3



    def initialize(options)
      @opts = DEFAULT_OPTS.merge(options)
      @data_array = @opts[:data_array]
      @data_array_size = @data_array.size
      @sample_size = @opts[:sample_size]
      @k_max = @opts[:k_max]
      @k_min = @opts[:k_min]
      @use_delta_n = @opts[:use_delta_n]
      @delta_n = calc_delta_n(@data_array_size, @k_max, @sample_size)
      check_config_error()

      @data_array_sum = [0.0]
      @data_array_size.times do |t|
        @data_array_sum[t+1] = @data_array_sum[t] + @data_array[t]
      end

      @rs_statistics = []
      @rs_statistics_mean = []
      @rs_statistics_max = []
      @rs_statistics_min = []

      @log_rs_statistics = []
      @log_rs_statistics_mean = []
      @log_rs_statistics_min = []
      @log_rs_statistics_max = []

      @hurst_mean = 0.0
      @hurst_max = 0.0
      @hurst_min = 0.0

    end

    def calculate()
      begin
        set_of_rs_statistics = calc_rs_statistics()
      rescue KMinValueTooBigException
        @hurst_mean = 0.0
        @hurst_max = 0.0
        @hurst_min = 0.0
      else
        set_of_log_rs_statistics = calc_rs_statistics_logarithm(set_of_rs_statistics)
        hurst = calc_least_square(set_of_log_rs_statistics)
        @hurst_mean = hurst[0][1]
        @hurst_max = hurst[1][1]
        @hurst_min = hurst[2][1]
      end
      return @hurst_mean, @hurst_max, @hurst_min
    end

    private
    def calc_delta_n(data_array_size, k, sample_size)
      result = ((data_array_size-k)/(sample_size-1)).floor
      raise "delta_n is smaller than 1.0." if result <= 1.0
      return result
    end

    def check_config_error()
      if @data_array_size < @k_max
        raise "k_max is too big or data_array_size is too small."
      end
      check_k_error()
    end

    def v(j)
      v = j - 1
      @data_array_sum[j]
    end

    def s(n,k)
      avg = (@data_array_sum[n+k] - @data_array_sum[n]) / k
      sum = 0
      @data_array[n...n+k].each do |v|
        sum += (v - avg)**2
      end
      Math::sqrt(sum/k)
    end

    def r(n, k)
      array = []
      for j in 1..k
        array.push v(n+j) - v(n) - j.to_f*(v(n+k.to_f) - v(n))/k.to_f
      end
      r = array.max - array.min
      return r
    end

    def q(n,k)
      r(n,k) / s(n,k)
    end

    def check_k_error()
      if @k_min >= @k_max
        raise KMinValueTooBigException "k_min is not less than k_max."
      end
    end

    def need_delta_n?(k)
      if k <= @data_array_size/@sample_size
        return false
      end
      true
    end

    def calc_rs_statistics()


      for k in @k_min..@k_max
        rs_statistic = []
        m = 0
        n = 0
        loop do 
          if need_delta_n?(k) && @use_delta_n
            @delta_n = calc_delta_n(@data_array_size, k, @sample_size)
            n = m * @delta_n
          else
            n = m * k
          end
          break if n+k > @data_array_size

          q = q(n,k)

          if q.nan?
            new_options = @opts.update(:k_min => @opts[:k_min]+1)
            return RSAnalysis::Base.new(new_options).calc_rs_statistics
          end

          rs_statistic.push q
          m += 1
          break if @use_delta_n && m >= @sample_size
        end
        @rs_statistics[k] = rs_statistic
        @rs_statistics_mean[k] = rs_statistic.avg
        @rs_statistics_max[k] = rs_statistic.max
        @rs_statistics_min[k] = rs_statistic.min
      end
      return @rs_statistics, @rs_statistics_mean, @rs_statistics_max, @rs_statistics_min
    end

    def calc_rs_statistics_logarithm(set_of_rs_statistics)
      (@k_min..@k_max).each do |k|
        @log_rs_statistics[k] = set_of_rs_statistics[RS_INDEX][k].map{|v| Math::log(v)}
        @log_rs_statistics_mean[k] = Math::log(set_of_rs_statistics[RS_MEAN_INDEX][k])
        @log_rs_statistics_max[k] = Math::log(set_of_rs_statistics[RS_MAX_INDEX][k])
        @log_rs_statistics_min[k] = Math::log(set_of_rs_statistics[RS_MIN_INDEX][k])
      end
      return @log_rs_statistics, @log_rs_statistics_mean, @log_rs_statistics_max, @log_rs_statistics_min
    end

    def calc_least_square(set_of_log_rs_statistics, limit = nil)
      x = GSL::Vector.alloc(@k_max - @k_min+1)
      y = GSL::Vector.alloc(@k_max - @k_min+1)
      y_max = GSL::Vector.alloc(@k_max - @k_min+1)
      y_min = GSL::Vector.alloc(@k_max - @k_min+1)
      if limit.nil?
        upper_limit = @k_max
      else
        upper_limit = limit
      end
      (@k_min..upper_limit).each_with_index do |k, i|
        x[i] = Math::log(k)
        y[i] = set_of_log_rs_statistics[RS_MEAN_INDEX][k]
        y_max[i] = set_of_log_rs_statistics[RS_MAX_INDEX][k]
        y_min[i] = set_of_log_rs_statistics[RS_MIN_INDEX][k]
      end
      options={}
      c0_mean, c1_mean = least_square_fit(x, y, options)
      c0_max, c1_max = least_square_fit(x, y_max, options)
      c0_min, c1_min = least_square_fit(x, y_min, options)
      return [c0_mean, c1_mean], [c0_max, c1_max], [c0_min, c1_min]
    end

  end
end
