require 'ruby-rs_analysis'
require 'traffic_utility'

include Timeseries

TIME_WINDOW_SIZE = 100
SLIDE_SIZE = 10
opts = {
  :k_max => 50,
  :k_min => 2,
  :sample_size => 20,
  :use_delta_n => true
}

file = File.open(ARGV[0], 'r')

## Input file without timestamp start
#lines_array = file.readlines.delete_if{|line| line.include?("#")}
#lines_array = lines_array.map.with_index{|line,index| Time.at(index).to_f.to_s+" "+line}
## Input file without timestamp end

## Input with timestamp file start
lines_array = file.readlines.delete_if{|line| line.include?("#")}
## Input with timestamp file end

timestamp_array = []
data_array = []
lines_array.each_with_index do |line|
  timestamp_array << line.split(" ")[0].to_f
  data_array << line.split(" ")[1].to_f
end


timewindow = Timewindow.new(TIME_WINDOW_SIZE,SLIDE_SIZE)
timestamp_timewindow = Timewindow.new(TIME_WINDOW_SIZE,SLIDE_SIZE)

data_array = data_array.each_slice(SLIDE_SIZE).to_a
timestamp_array = timestamp_array.each_slice(SLIDE_SIZE).to_a

logger = RSAnalysis::Logger.new(File.basename(ARGV[0]))
data_num = 0

logger.out_initial_config(opts)

data_array.each_with_index do |data, index|
  if timewindow.is_full? == false
    timewindow.add(data)
    timestamp_timewindow.add(timestamp_array[index])
  else
    opts.update({:data_array=>timewindow.to_a})

    rs = RSAnalysis::Base.new(opts)
    hurst = rs.calculate
    logger.hurst(hurst, data_num, timestamp_timewindow.to_a.last)
    logger.out_adjusted_config(rs.opts, data_num)
    logger.rs_statistics(rs.log_rs_statistics, data_num)
    logger.timeseries(timewindow.to_a, timestamp_timewindow.to_a, data_num)
    timewindow.add(data)
    timestamp_timewindow.add(timestamp_array[index])
    data_num += 1
  end
end
