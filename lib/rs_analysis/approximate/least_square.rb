require 'gsl'
module Approximate
  def least_square_fit(x, y, options={})
    options = {
      :fit => :linear
    }.merge(options)
    case options[:fit]
    when :linear
      c0, c1, cov00, cov01, cov11, chisq, status = GSL::Fit.linear(x, y)
      return [c0, c1]
    when :nonlinear
      # power fit
      coef, err, chi2, dof = GSL::MultiFit::FdfSolver.fit(-x, y, "power")
      # exp fit
      #sigma = GSL::Vector[x.size]
      #sigma.set_all(0.1)
      #coef, err, chi2, dof = GSL::MultiFit::FdfSolver.fit(x, sigma, y, "exponential")
      y0 = coef[0]
      amp = coef[1]
      b = coef[2]
      return [y0, amp, b]
    end
    []
  end
end
