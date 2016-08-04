# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160804043249) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cron_logs", force: :cascade do |t|
    t.string   "table_name"
    t.text     "content"
    t.integer  "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dependencies", force: :cascade do |t|
    t.string   "requirements"
    t.string   "provisional_name"
    t.integer  "plugin_id"
    t.integer  "entry_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["entry_id"], name: "index_dependencies_on_entry_id", using: :btree
    t.index ["plugin_id"], name: "index_dependencies_on_plugin_id", using: :btree
  end

  create_table "entries", force: :cascade do |t|
    t.string   "title"
    t.datetime "published"
    t.text     "content"
    t.string   "url"
    t.string   "author"
    t.integer  "plugin_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "major_version"
    t.integer  "minor_version"
    t.string   "patch_version"
    t.index ["plugin_id"], name: "index_entries_on_plugin_id", using: :btree
  end

  create_table "plugins", force: :cascade do |t|
    t.string   "name"
    t.string   "newest"
    t.string   "pre"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "source_code_uri"
    t.string   "homepage_uri"
  end

  create_table "project_versions", force: :cascade do |t|
    t.string   "newest"
    t.string   "installed"
    t.string   "pre"
    t.integer  "project_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "requested"
    t.integer  "major_version"
    t.integer  "minor_version"
    t.string   "patch_version"
    t.boolean  "described"
    t.integer  "plugin_id"
    t.integer  "entry_id"
    t.index ["entry_id"], name: "index_project_versions_on_entry_id", using: :btree
    t.index ["plugin_id"], name: "index_project_versions_on_plugin_id", using: :btree
    t.index ["project_id"], name: "index_project_versions_on_project_id", using: :btree
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "gitlab_id"
    t.string   "http_url_to_repo",  default: "", null: false
    t.string   "ssh_url_to_repo",   default: "", null: false
    t.string   "commit_id"
    t.text     "gemfile_content"
    t.string   "web_url"
    t.text     "description"
    t.datetime "gitlab_created_at"
    t.datetime "gitlab_updated_at"
  end

  create_table "security_advisories", force: :cascade do |t|
    t.integer  "plugin_id"
    t.string   "framework"
    t.string   "cve"
    t.integer  "osvdb"
    t.text     "description"
    t.string   "cvss_v2"
    t.string   "cvss_v3"
    t.date     "date"
    t.string   "unaffected_versions"
    t.string   "patched_versions"
    t.string   "path"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["plugin_id"], name: "index_security_advisories_on_plugin_id", using: :btree
  end

  create_table "security_entries", force: :cascade do |t|
    t.string   "title"
    t.datetime "published"
    t.text     "content"
    t.string   "url"
    t.string   "author"
    t.integer  "genre"
    t.integer  "plugin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plugin_id"], name: "index_security_entries_on_plugin_id", using: :btree
  end

  add_foreign_key "dependencies", "entries"
  add_foreign_key "dependencies", "plugins"
  add_foreign_key "entries", "plugins"
  add_foreign_key "project_versions", "entries"
  add_foreign_key "project_versions", "plugins"
  add_foreign_key "project_versions", "projects"
  add_foreign_key "security_advisories", "plugins"
  add_foreign_key "security_entries", "plugins"
end
