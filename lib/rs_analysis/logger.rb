module RSAnalysis
  class Logger

    def initialize(source_file_name, options)
      @file_name = source_file_name
      @opts = options
      # delete hurst_logger
      
      @hurst_logger = File.open(@file_name+".hurst", 'w')
      @hurst_logger.puts "# Number Hurst Hsup Hinf"
      @hurst_logger.close
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
      end
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
