require 'open-uri'
require 'open_uri_redirections'
require 'nokogiri'

module GemWatcher
  #
  # CHANGE.logからCVE番号を取得する
  #
  module ScrapeCveNumber

    extend ActiveSupport::Concern

    included do

      # このページのCVE-0000-0000を配列で返す
      def cve_numbers(change_log_url)
        begin
          charset = nil
          _html = open(change_log_url, :allow_redirections => :safe) do |f|
            charset = f.charset # 文字種別を取得
            f.read              # htmlを読み込んで変数htmlに渡す
          end
        rescue OpenURI::HTTPError
          return [] # changelogが見つからなかった場合
        end
        # htmlをパース(解析)してオブジェクトを生成
        doc = Nokogiri::HTML.parse(_html)#, nil, charset
        node = doc.xpath('//article[@class="markdown-body entry-content"]')
        words = node.text.scan(/CVE-\d+-\d+/) if node.text.at('CVE-')
        if words
          words.uniq!
          return words.sort.reverse
        else
          return []
        end
      end

    end

  end
end