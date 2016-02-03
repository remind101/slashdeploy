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

ActiveRecord::Schema.define(version: 20160203113511) do

  create_table "environments", force: :cascade do |t|
    t.string   "repository"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "environments", ["repository", "name"], name: "index_environments_on_repository_and_name", unique: true

  create_table "locks", force: :cascade do |t|
    t.string   "message"
    t.boolean  "active",         default: false, null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "environment_id"
  end

  add_index "locks", ["environment_id"], name: "index_locks_on_environment_id"
  add_index "locks", ["environment_id"], name: "locked_environment", unique: true, where: "active"

  create_table "users", id: false, force: :cascade do |t|
    t.string   "id",           null: false
    t.string   "github_token", null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

end
