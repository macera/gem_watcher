# TODO: 仕様変更によるデプロイ時に削除・作成順を見直す
# TODO: Gemfileのないプロジェクトをseedとかで一気に登録するようにしたい

# GitLabからprojectを取得し、projectsテーブルを作成する
SecurityAdvisory.destroy_all
Dependency.destroy_all
p '*0'
Project.destroy_all
p '*1'
Plugin.destroy_all
p '*2'
CronLog.destroy_all
p '*3'
Project.add_projects({ sort: true })
p '*4'
Plugin.create_runtime_dependencies
p '*5'
SecurityAdvisory.source_update
p '*6'
SecurityAdvisory.all_update
p '*7'
ProjectVersion.update_vulnerable_versions
