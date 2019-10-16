class BugIssue
  RANK_ERROR_THRESHOLD = 4
  attr_accessor :buginfo
  attr_accessor :source_directory

  def initialize(buginfo, source_directory)
    @buginfo = buginfo
    @source_directory = source_directory
  end

  def rank
    @rank ||= buginfo.attribute("rank").value.to_i
  end

  def type
    @type ||= rank > RANK_ERROR_THRESHOLD ? :warn : :fail
  end

  def line
    @line ||= buginfo.xpath("SourceLine/@start").first.to_s.to_i
  end

  def source_path
    @source_path ||= buginfo.xpath("SourceLine/@sourcepath").first.to_s
  end

  def description
    @description ||= buginfo.xpath("LongMessage/text()").first.text
  end

  def absolute_path
    @absolute_path ||= Pathname.new(@source_directory).join(source_path).to_s
  end

end
