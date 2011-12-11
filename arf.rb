#!/usr/bin/env ruby

# TODO: expect to capture responses for recipes
# TODO: list command to list out recipes available
# TODO: merge command to merge in branches instead of running recipes
# TODO: rebase command to rebase in branches instead of running recipes
# TODO: git integration (commit after each recipe, take message from description)
# TODO: allow use of local recipes (maybe stored in github)
# TODO: look over recipes from rails_apps_composer and see what to use
# TODO: name - ARF - APB Rails Frameworker? APB - ARF Project Builder
# TODO: add namespacing to recipe definitions
# TODO: setup dependencies between recipes (maybe use Rake? suck in recipes as tasks from rails_wizard)
# TODO: simple site for browsing current recipes (search by tags, etc)
# TODO: simple way to confederate other recipes (add by url?, add other repo (namespaced)?)
# TODO: show how to add new recipes to an existing project (branch at original rails commit, run recipe, merge)
# TODO: how can we include methods like env() in the env_yaml recipe
# TODO: way to figure out if recipes have already been applied as part of depends process (look at git history? token in app? dotfile?)
# TODO: config questions have default answers defined in recipe wrappers, but can send --yes to all of them
# TDOO: way to selectively not use defaults for some recipes
# TODO: Haml.builder to modify haml files safely
# TODO: example of how to include recipes in a gem or github account for use (click to apply?, example command to run?)

require 'rubygems'
require 'bundler/setup'

require 'pp'
require 'ruby-debug'

require 'tempfile'
require 'rails_wizard'
require 'rails/generators'


class ArfTemplateRunner < Rails::Generators::Base
  def initialize(args, opts, config)
    super
    @template = args.first
    @template_dir = File.dirname(@template)
    @template_file = File.basename(@template)
    ArfTemplateRunner.source_root @template_dir
  end

  desc "This generator runs a rails template at any time (not limited to application creation time)"
  def apply_template
    apply @template_file
  end
end


class ArfConfig
  def initialize
    @config = Hash.new
  end

  def [](key)
    raise "Unknown config option #{key}" unless @config.has_key? key
    @config[key]
  end

  def method_missing(sym, value)
    @config[sym] = value
  end
end


class Arf

  def config(&block)
    return @config unless block_given?
    @config = ArfConfig.new.tap do |config|
      config.instance_eval &block
    end
  end

  def recipe(name)
    if block_given?
      yield
    else
      puts "recipe: #{name}"
      Tempfile.open('template') do |file|
        template = RailsWizard::Template.new([name])
        file.write template.compile
        file.close
        ArfTemplateRunner.start([file], :behavior => :invoke, :destination_root => config[:appname])
      end
    end
  end
end

arf = Arf.new
ARGV.each do |file|
  arf.instance_eval File.read(file), file
end
