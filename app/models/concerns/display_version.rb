module DisplayVersion
  extend ActiveSupport::Concern

  # 0.0.0.0.0のようなバージョンもあるのでsplitメソッドは使えない
  def split_version(string)
    version = string.scan(/(\d+)\.(\d+)\.(\d+)\.(\S+)/).first # 0.0.0.0
    version = string.scan(/(\d+)\.(\d+)\.(\d+)/).first unless version # 0.0.0
    version = string.scan(/(\d+)\.(\d+)/).first unless version # 0.0
    version = string.scan(/(\d+)/).first unless version # 0
    return version
  end

  def skip_alphabetic_version_to_next(version)
    patch = version[2]
    return version if patch.blank?
    match_index = patch =~ /[a-zA-Z]+/
    if match_index
      tmp = patch[match_index..-1]
      version[2].slice!(match_index..-1)
      version[2] = version[2]
      version[3] = tmp + version[3].to_s
    end
    version
  end

end