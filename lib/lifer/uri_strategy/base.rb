class Lifer::URIStrategy::Base
  attr_reader :directory

  def initialize(directory:)
    @directory = directory
  end

  def name
    raise NotImplementedError, "implement on a subclass"
  end

  def dirname_for(entry)
    raise NotImplementedError, "implement on a subclass"
  end

  def file_for(entry)
    raise NotImplementedError, "implement on a subclass"
  end
end
