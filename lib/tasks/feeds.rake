# feedを登録するタスク
# rake feeds:generate
namespace :feeds do

  # rubygemorg リリースフィード取得
  task generate: [:environment] do
    Plugin.all.each do |plugin|
      Entry.update_list(plugin)
    end
  end

end
