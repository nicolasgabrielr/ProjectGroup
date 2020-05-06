ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'sequel'
require 'sinatra'
DB = Sequel.connect(
  adapter: 'postgres',
  database: 'notificator_test',
  host: 'db',
  user: 'unicorn',
  password: 'magic')
require File.expand_path './app.rb'
