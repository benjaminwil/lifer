class MovieReviews < Lifer::Selection
  def entries
    @entries ||=
      Lifer::Entry::Markdown.all.select { |entry|
        entry.frontmatter[:tags]&.include?("review")
      }
  end
end
