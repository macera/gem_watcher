module DisplayVersion
  extend ActiveSupport::Concern

  included do
    # 0.0.0.0のようなバージョンもあるのでsplitメソッドは使えない
    def split_version(string)
      version = string.scan(/(\d+)\.(\d+)\.(\S+)/).first # 0.0.0
      version = string.scan(/(\d+)\.(\d+)/).first unless version # 0.0
      version = string.scan(/(\d+)/).first unless version # 0
      return version
    end
  end
end