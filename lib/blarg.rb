require "blarg/version"
require 'pry'
require 'camping'

BLOG_REPO = '/Users/Chubes/labs/guessr/lib/blarg/improvedmeans/'

Camping.goes :Blarg

module Blarg
  module Models
    class Post < Base
      serialize :tags
    end

    class InitializeDatabase < V 1.0
      def self.up
        create_table Post.table_name do |t|
          t.string :title
          t.string :tags
          t.string :format
          t.datetime :written
          t.text :text
        end
      end

      def self.down
        drop_table Post.table_name
      end
    end

    class RenameWrittenToDate < V 1.1
      def self.up
        rename_column Post.table_name, :written, :date
      end

      def self.down
        rename_column Post.table_name, :date, :written
      end
    end
  end
end

def find_controller(request)
  @routing.each do |route, controller|
    if request.url =~ route
      @controller = controller.new(request)
    end
  end
end

module Blarg::Controllers
  
  class PostId < R '/posts/(\d+)'
    def get(id)
      post = Blarg::Models::Post.find(id)
      post.to_json
    end

    def put(id)

    end

    def delete(id)
      post = Blarg::Models::Post.find(id)
      post.destroy
      @status = 204
      ""
    end
  end

  class PostController < R '/posts'
    def get

    end

    def post
      new_post = Blarg::Models::Post.create(@input)
      new_post.to_json
    end

  class Intro < R '/welcome/to/the/([^/]+)'
    def get
    "This is the intro controller"
    end
  end
end

module Promptable
  def prompt(question, validator, error_msg, clear: nil)
    `clear` if clear
    puts "\n#{question}\n"
    result = $stdin.gets.chomp
    until result =~ validator
      puts "\n#{error_msg}\n"
      result = $stdin.gets.chomp
    end
    puts
    result
  end
end

class PostImporter
  include Enumerable
  include Promptable

  def initialize(posts_dir)
    @posts_dir = posts_dir
    choices = {}
    self.each_with_index do |post, i|
      choices[i+1] = post
    end
    @choices = choices
  end

  # NOTE: Trailing slash matters here.
  def each
    Dir.glob(@posts_dir + '*.post').each { |post| yield post }
  end

  def parse_post(file)
    result = {}
    File.open(file, 'r') do |f|
      result = parse_header(f)
      result[:text] = f.read
      result[:date] = DateTime.parse(result[:date])
      result[:tags] = result[:tags].split(', ')
    end
    result
  end

  def choose_post
    @choices.each do |i, post|
      puts "(#{i}) -- #{File.basename(post)}"
    end
    result = prompt("Which post would you like to import from your previous blog?",
                    /^#{@choices.keys.join('|')}$/,
                    "Please choose one of the listed numeric options.")
    path = @choices[result.to_i]
    parse_post(path)
  end

  private
  def marker?(line)
    line.chomp == ';;;;;'
  end

  def parse_header(fd)
    result = {}
    unless marker?(fd.readline)
      raise "The file '#{file}' does not have a valid header."
    end
    line = fd.readline
    until marker?(line)
      key, val = parse_metadata(line)
      result[key.to_sym] = val
      line = fd.readline
    end
    result
  end

  def parse_metadata(line)
    matcher = /^([a-zA-Z]+):\s+(.*)$/
    matches = line.match(matcher)
    return matches[1], matches[2]
  end
end

class BlogApp
  include Promptable

  def initialize
    @importer = PostImporter.new BLOG_REPO
  end

  def run
    puts "Hello there. Welcome to your personal blaaaarg!"
    # TODO: Have choose method for post screen or index screen.
    post_screen
  end

  def self.quit_handler
    puts "Thanks for blarging! Goodbye!"
    exit
  end

  private
  def import_post
    choice = prompt("Would you like to import a post? (yes/y, no/n, all)",
                  /^y|yes|n|no|all$/, "Please choose 'y', 'yes', 'n', 'no', or 'all'.")
    if choice == 'all'
      @importer.each do |p|
        opts = @importer.parse_post(p)
        Blarg::Models::Post.create(opts)
      end
    elsif ['y','yes'].include?(choice)
      opts = @importer.choose_post
      Blarg::Models::Post.create(opts)
    else
      puts "Your posts are imported. Thanks for stopping by!"
      BlogApp.quit_handler
    end
  end

  def post_screen
    message = "Would you like to (1) write a new post, (2) import a post from another blog, (3) find an existing post, or (QUIT)?"
    choice = prompt(message, /^([123]|QUIT)$/, "Please choose 1, 2, 3, or QUIT.", clear: true)
    case choice.to_i
    when 1
      add_post
    when 2
      import_post
    when 3
      # TODO: We might want to edit or delete a post that we find.
      find_post
    else
      BlogApp.quit_handler
    end
  end

  def index_screen
    message = "Would you like to (1) view indexes by date, (2) view indexes by tag, or (QUIT)?"
    choice = prompt(message, /^([12]|QUIT)$/, "Please choose 1, 2, or QUIT.", clear: true)
    case choice.to_i
    when 1
      view_date_index
    when 2
      view_tag_index
    else
      BlogApp.quit_handler
    end
  end
end

def top_tags
  result = {}
  Blarg::Models::Post.find_each do |p|
    result[p] = 0
    p.tags.each do |t|
      result[p] += 1
    end
  end
  top_tags = result.sort_by{ |k, v| -v }.first(10)
end

def top_months
  sqlite_month = "strftime (%m, date)"
  grouped = Blarg::Models::Post.
end

def Blarg.create
  Blarg::Models.create_schema
end

#blog = BlogApp.new
#blog.run
