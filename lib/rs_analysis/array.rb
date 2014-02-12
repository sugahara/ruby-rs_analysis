class Array
  def avg
    self.inject(:+)/self.size.to_f
  end
end
