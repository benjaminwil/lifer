class Lifer::Collection::Pseudo::IncludedInFeeds < Lifer::Collection::Pseudo
  def entries
    Lifer::Entry.manifest.select { |entry| entry.class.include_in_feeds }
  end
end
