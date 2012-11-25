class String
  def pluralize
    self + "s"
  end

  def singularize
    self[0..-2]
  end
  
  def classify
    singularize.camelize
  end
end
