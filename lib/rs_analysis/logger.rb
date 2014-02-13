module RSAnalysis
  class Logger

    def initialize(source_file_name, options)
      @file_name = source_file_name
      @opts = options      
      hurst_logger = File.open(@file_name+".hurst", 'w')
      hurst_logger.puts "# k_min=#{@opts[:k_min]}"
      hurst_logger.puts "# k_max=#{@opts[:k_max]}"
      hurst_logger.puts "# sample_size=#{@opts[:sample_size]}"
      hurst_logger.puts "# use_delta_n=#{@opts[:use_delta_n]}"
      hurst_logger.puts "# #{Time.now}"
      hurst_logger.puts "# Number Hurst Hsup Hinf"
      hurst_logger.close
    end

    def hurst(data, number)
      @hurst_logger = File.open(@file_name+".hurst", 'a'){|f|
        f.puts "#{number} #{data[0]} #{data[1]} #{data[2]}"
      }
    end

    def rs_statistics(data, number)
      File.open(@file_name+".#{number}.rs_stat", 'w'){|f|
        data.each_with_index do |samples, k|
          next if samples.nil?
          statistics_mean = samples.inject(:+) / samples.size.to_f
          samples.each do |statistics|
            f.puts "#{Math::log(k)} #{statistics} #{statistics_mean}"
          end
        end
      }
    end

    def timeseries(data, timestamp, number)
      File.open(@file_name+".#{number}.ts",'w'){|f|
        data.each_with_index do |value, i|
          f.puts "#{timestamp[i]} #{value}"
        end
      }
    end
  end
end
