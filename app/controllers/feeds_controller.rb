
class FeedsController < ApplicationController

  # トップ画面 フィード一覧
  def index
    @rails_entries = Entry.rails_entries

    @search = Entry.newest_plugins.ransack(params[:q])
    @entries = @search.result.page(params[:page])

    # alert = Project.joins(:project_versions).where('project_versions.vulnerability' => true)
    # if alert.present?
    #   flash.now['alert'] = "脆弱性のあるgemが定義されたプロジェクトがあります"
    # end
  end

end
