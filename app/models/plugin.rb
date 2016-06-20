# == Schema Information
#
# Table name: plugins
#
#  id              :integer          not null, primary key
#  name            :string
#  newest          :string
#  pre             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  source_code_uri :string
#  homepage_uri    :string
#

class Plugin < ActiveRecord::Base
  has_many :project_versions
  has_many :projects, through: :project_versions
  has_many :entries, dependent: :destroy
  has_many :security_entries, dependent: :destroy

  validates :source_code_uri, presence: true
  validates :source_code_uri, length: { maximum: 200 }, allow_blank: true
  validates :source_code_uri, format: {
                                with: /\A#{URI::regexp(%w(http https))}\/\z/,
                                message: "はURL形式で入力して下さい。末尾は/で終了する必要があります。"
                              },
                              allow_blank: true,
                              on: :update

  # before_create :get_source_code_uri

  #scope :production, -> { joins(:project_versions).merge(ProjectVersion.production).uniq }

  # 許可するカラムの名前をオーバーライドする
  def self.ransackable_attributes(auth_object = nil)
    %w(name)
  end

  # 許可する関連の配列をオーバーライドする
  # def self.ransackable_associations(auth_object = nil)
  #   reflect_on_all_associations.map { |a| a.name.to_s }
  # end

  # def self.ransackable_scopes(auth_object = nil)
  #   %i[]
  # end

  # Gemの情報を代入する
  def get_gem_uri
    gem_info = Gems.info(name)
    if gem_info.is_a?(Hash)
      path = gem_info['source_code_uri'].presence || gem_info['homepage_uri']
      self.source_code_uri = add_trailing_slash(path) if path
      self.homepage_uri = gem_info['homepage_uri']
    end
  end

  private

    # trailing slashを追加する
    def add_trailing_slash(path)
      # TODO: trailing slashを常に付ける方法が分からない
      path += '/' if path && path.last != '/'
      path
    end

end
