# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160610070619) do

  create_table "entries", force: :cascade do |t|
    t.string   "title"
    t.datetime "published"
    t.text     "content"
    t.string   "url"
    t.string   "author"
    t.integer  "plugin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "entries", ["plugin_id"], name: "index_entries_on_plugin_id"

  create_table "plugins", force: :cascade do |t|
    t.string   "name"
    t.string   "newest"
    t.string   "pre"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "source_code_uri"
  end

  create_table "project_versions", force: :cascade do |t|
    t.string   "newest"
    t.string   "installed"
    t.string   "pre"
    t.integer  "project_id"
    t.integer  "plugin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "requested"
  end

  add_index "project_versions", ["plugin_id"], name: "index_project_versions_on_plugin_id"
  add_index "project_versions", ["project_id"], name: "index_project_versions_on_project_id"

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "gitlab_id",        default: 0,  null: false
    t.string   "http_url_to_repo", default: "", null: false
    t.string   "ssh_url_to_repo",  default: "", null: false
    t.string   "commit_id"
    t.text     "gemfile_content"
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
  end

  add_index "security_entries", ["plugin_id"], name: "index_security_entries_on_plugin_id"

end
