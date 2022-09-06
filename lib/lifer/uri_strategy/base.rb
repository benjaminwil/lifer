class Lifer::URIStrategy::Base
  attr_reader :root

  def initialize(root:)
    @root = root
  end

  def name
    raise NotImplementedError, "implement on a subclass"
  end

  def output_file(entry)
    raise NotImplementedError, "implement on a subclass"
  end
end
