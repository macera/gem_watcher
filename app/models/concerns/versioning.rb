module Versioning
  extend ActiveSupport::Concern

  def skip_alphabetic_version_to_next(version_array)
    patch = version_array[2]
    return version_array if patch.blank?
    match_index = patch =~ /[a-zA-Z]+/
    if match_index
      tmp = patch[match_index..-1]
      version_array[2].slice!(match_index..-1)
      version_array[2] = version_array[2]
      version_array[3] = tmp + version_array[3].to_s
    end
    version_array
  end

end
