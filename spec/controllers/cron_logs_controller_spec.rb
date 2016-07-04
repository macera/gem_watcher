require 'rails_helper'

describe CronLogsController do

  describe 'GET #index' do
    it "すべてのログを配列で返却されること" do
      cron_log = create(:cron_log)
      get :index
      expect(assigns(:logs)).to eq [cron_log]
    end

    it "indexテンプレートが表示されること" do
      get :index
      expect(response).to render_template :index
    end
  end

end