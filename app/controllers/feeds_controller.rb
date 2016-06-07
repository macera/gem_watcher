
class FeedsController < ApplicationController
  require "feedjira"

  def index
    feeds = []
    Plugin.all.each do |plugin|
      # TODO: あとで見直す。通常のgithub以外のリポジトリ使っているgem
      if plugin.source_code_uri =~ /\/\/github.com/
        path = URI.join(plugin.source_code_uri, 'releases.atom')
        begin
          feeds << Feedjira::Feed.fetch_and_parse(path.to_s)
        rescue
          p 'feedを取得できません'
          p 'プラグイン名:' + plugin.name
          p 'パス:' + path.to_s
        end
      end
    end
    # 降順
    feeds.sort_by! {|feed| feed.last_modified.to_i }
    @feeds = feeds.reverse

  end

  def show
  end
end
