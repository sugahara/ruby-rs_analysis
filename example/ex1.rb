require 'ruby-rs_analysis'




file = File.open(ARGV[0], 'r')
data_array = file.readlines.map{|v| v.to_f}

opts = {
  :k_max => 200,
  :k_min => 2,
  :sample_size => 50,
  :use_delta_n => true,
  :data_array => data_array
}

rs = RSAnalysis::Base.new(opts)

p rs.calculate
