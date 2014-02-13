module RSAnalysis
  class Logger

    def initialize(source_file_name)
      @file_name = source_file_name
    end

    def out_initial_config(opts)
      File.open(@file_name+".hurst", 'w'){|f|
        f.puts "# k_min=#{opts[:k_min]}"
        f.puts "# k_max=#{opts[:k_max]}"
        f.puts "# sample_size=#{opts[:sample_size]}"
        f.puts "# use_delta_n=#{opts[:use_delta_n]}"
        f.puts "# #{Time.now}"
        f.puts "# Number H Hsup Hinf"
      }
    end

    def out_adjusted_config(opts, number)
      File.open(@file_name+".#{number}.rs_stat", 'w'){|f|
        f.puts "# k_min=#{opts[:k_min]}"
        f.puts "# k_max=#{opts[:k_max]}"
        f.puts "# sample_size=#{opts[:sample_size]}"
        f.puts "# use_delta_n=#{opts[:use_delta_n]}"
        f.puts "# #{Time.now}"
        f.puts "# log(k) rs_statistics rs_statistics_mean"
      }
    end

    def hurst(data, number)
      File.open(@file_name+".hurst", 'a'){|f|
        f.puts "#{number} #{data[0]} #{data[1]} #{data[2]}"
      }
    end

    def rs_statistics(data, number)
      File.open(@file_name+".#{number}.rs_stat", 'a'){|f|
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
