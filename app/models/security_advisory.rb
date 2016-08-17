# == Schema Information
#
# Table name: security_advisories
#
#  id                  :integer          not null, primary key
#  plugin_id           :integer
#  framework           :string
#  cve                 :string
#  osvdb               :integer
#  description         :text
#  cvss_v2             :string
#  cvss_v3             :string
#  date                :date
#  unaffected_versions :string
#  patched_versions    :string
#  path                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  url                 :string
#
# Indexes
#
#  index_security_advisories_on_plugin_id  (plugin_id)
#
# Foreign Keys
#
#  fk_rails_da13a8de4a  (plugin_id => plugins.id)
#

#
# ruby-advisory-dbからセキュリティデータを取得する
# 参考: https://github.com/rubysec/bundler-audit/blob/master/lib/bundler/audit/database.rb
#
class SecurityAdvisory < ApplicationRecord
  belongs_to :plugin

  after_create  :create_created_table_log
  #after_destroy :create_destroyed_table_log

  REPOSITORY = Settings.git.ruby_advisory_db
  # Default path to the ruby-advisory-db
  USER_PATH =  Rails.root.join(Settings.path.data_directory)
  # Timestamp for when the database was last updated
  #VENDORED_TIMESTAMP = Time.parse(File.read("#{VENDORED_PATH}.ts")).utc

  # Path to the user's copy of the ruby-advisory-db
  #USER_PATH = Rails.root.join('tmp', "projects", "data", "ruby-advisory-db")
  def self.source_update
    if File.directory?(USER_PATH)
      if File.directory?(File.join(USER_PATH, ".git"))
        Dir.chdir(USER_PATH) do
          system 'git', 'pull', 'origin', 'master'
        end
      end
    else
      system 'git', 'clone', REPOSITORY, USER_PATH.to_s
    end
  end

  def self.all_update
    Plugin.all.each do |plugin|
      directory = USER_PATH.join('gems', plugin.name)
      next unless directory.exist?
      Dir.glob(directory.join('*.yml')).each do |path|
        load(path, plugin)
      end
    end
  end

  def self.load(path, plugin)
    data = YAML.load_file(path)
    unless data.kind_of?(Hash)
      raise("advisory data in #{path.dump} was not a Hash")
    end

    advisory = plugin.security_advisories.where(path: path).first_or_initialize
    advisory.update_attributes!(
      framework:           data['framework'],
      cve:                 data['cve'],
      osvdb:               data['osvdb'],
      url:                 data['url'],
      description:         data['description'],
      cvss_v2:             data['cvss_v2'],
      cvss_v3:             data['cvss_v3'],
      date:                data['date'],
      unaffected_versions: (data['unaffected_versions'] || []).join(':'),
      patched_versions:    (data['patched_versions'] || []).join(':')
    )

  end

  def self.check_gem(plugin, version)
    advisories = []
    plugin.security_advisories.order('date desc').each do |advisory|
      if advisory.vulnerable?(version)
        advisories << advisory
      end
    end
    advisories
  end

  def title
    cve_id || osvdb_id
  end

  def cve_id
    "CVE-#{cve}" if cve
  end

  def osvdb_id
    "OSVDB-#{osvdb}" if osvdb
  end

  def unaffected_versions_list
    unaffected_versions.to_s.split(':').join('、')
  end

  def patched_versions_list
    patched_versions.to_s.split(':').join('、')
  end

  def unaffected?(version)
    parse_versions(unaffected_versions).any? do |unaffected_version|
      unaffected_version === Gem::Version.create(version)
    end
  end

  def patched?(version)
    parse_versions(patched_versions).any? do |patched_version|
      patched_version === Gem::Version.create(version)
    end
  end

  # version(引数)は脆弱か
  def vulnerable?(version)
    !patched?(version) && !unaffected?(version)
  end

  private

  def parse_versions(string)
    versions = string.to_s.split(':')
    Array(versions).map do |version|
      Gem::Requirement.new(*version.split(', '))
    end
  end

  # 新規脆弱性情報作成ログ
  def create_created_table_log
    CronLog.success_table(self.class.to_s.underscore, "#{plugin.name}: #{title}", :create)
  end

  # 脆弱性情報削除ログ
  # def create_destroyed_table_log
  #   CronLog.success_table(self.class.to_s.underscore, "#{plugin.name}: #{title}", :delete)
  # end

end
