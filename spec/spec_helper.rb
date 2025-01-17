# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'active_support'
require 'action_pack'
require 'action_view'
require 'action_controller'
require 'action_dispatch'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/formtastic/util'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/formtastic'))

#rspec-rails 2-14 assumes a full rails install
module Rails
  module VERSION
    include ActionPack::VERSION
  end
end

require 'ammeter/init'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories in alphabetic order.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each {|f| require f}

I18n.enforce_available_locales = false if I18n.respond_to?(:enforce_available_locales)

module FakeHelpersModule
end

module FormtasticSpecHelper
  include ActionPack
  include ActionView::Context if defined?(ActionView::Context)
  include ActionController::RecordIdentifier if defined?(ActionController::RecordIdentifier)
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::ActiveRecordHelper if defined?(ActionView::Helpers::ActiveRecordHelper)
  include ActionView::Helpers::ActiveModelHelper if defined?(ActionView::Helpers::ActiveModelHelper)
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::AssetTagHelper
  include ActiveSupport
  include ActionController::PolymorphicRoutes if defined?(ActionController::PolymorphicRoutes)
  include ActionDispatch::Routing::PolymorphicRoutes 
  include AbstractController::UrlFor if defined?(AbstractController::UrlFor)
  include ActionView::RecordIdentifier if defined?(ActionView::RecordIdentifier)
  
  include Formtastic::Helpers::FormHelper

  def default_input_type(column_type, column_name = :generic_column_name)
    @new_post.stub(column_name)
    @new_post.stub(:column_for_attribute).and_return(double('column', :type => column_type)) unless column_type.nil?

    semantic_form_for(@new_post) do |builder|
      @default_type = builder.send(:default_input_type, column_name)
    end

    return @default_type
  end

  def active_model_validator(kind, attributes, options = {})
    validator = double("ActiveModel::Validations::#{kind.to_s.titlecase}Validator", :attributes => attributes, :options => options)
    validator.stub(:kind).and_return(kind)
    validator
  end

  def active_model_presence_validator(attributes, options = {})
    active_model_validator(:presence, attributes, options)
  end

  def active_model_length_validator(attributes, options = {})
    active_model_validator(:length, attributes, options)
  end

  def active_model_inclusion_validator(attributes, options = {})
    active_model_validator(:inclusion, attributes, options)
  end

  def active_model_numericality_validator(attributes, options = {})
    active_model_validator(:numericality, attributes, options)
  end

  class ::MongoPost
    include MongoMapper::Document if defined?(MongoMapper::Document)

    def id
    end

    def persisted?
    end
  end


  class ::Post
    extend ActiveModel::Naming if defined?(ActiveModel::Naming)
    include ActiveModel::Conversion if defined?(ActiveModel::Conversion)

    def id
    end

    def persisted?
    end
  end

  module ::Namespaced
    class Post
      extend ActiveModel::Naming if defined?(ActiveModel::Naming)
      include ActiveModel::Conversion if defined?(ActiveModel::Conversion)

      def id
      end

      def persisted?
      end
    end
  end

  class ::Author
    extend ActiveModel::Naming if defined?(ActiveModel::Naming)
    include ActiveModel::Conversion if defined?(ActiveModel::Conversion)

    def to_label
    end

    def persisted?
    end
  end

  class ::HashBackedAuthor < Hash
    extend ActiveModel::Naming if defined?(ActiveModel::Naming)
    include ActiveModel::Conversion if defined?(ActiveModel::Conversion)
    def persisted?; false; end
    def name
      'hash backed author'
    end
  end

  class ::Continent
    extend ActiveModel::Naming if defined?(ActiveModel::Naming)
    include ActiveModel::Conversion if defined?(ActiveModel::Conversion)
  end

  class ::PostModel
    extend ActiveModel::Naming if defined?(ActiveModel::Naming)
    include ActiveModel::Conversion if defined?(ActiveModel::Conversion)
  end

  ##
  # We can't mock :respond_to?, so we need a concrete class override
  class ::MongoidReflectionMock < RSpec::Mocks::Double
    def initialize(name=nil, stubs_and_options={})
      super name, stubs_and_options
    end

    def respond_to?(sym)
      sym == :options ? false : super
    end
  end
  
  # In Rails 3 Model.all returns an array. In Rails 4, it returns an
  # association proxy, which quacks a lot like an array. We use this in stubs 
  # or mocks where we need to return the later.
  # 
  # TODO try delegate?
  # delegate :map, :size, :length, :first, :to_ary, :each, :include?, :to => :array
  class MockScope
    attr_reader :array
    
    def initialize(the_array)
      @array = the_array
    end
    
    def map(&block)
      array.map(&block)
    end
    
    def where(*args)
      # array
      self
    end
    
    def includes(*args)
      self
    end
    
    def size
      array.size
    end
    alias_method :length, :size
    
    def first
      array.first
    end
    
    def to_ary
      array
    end
    
    def each(&block)
      array.each(&block)
    end
    
    def include?(*args)
      array.include?(*args)
    end
  end

  def _routes
    url_helpers = double('url_helpers')
    url_helpers.stub(:hash_for_posts_path).and_return({})
    url_helpers.stub(:hash_for_post_path).and_return({})
    url_helpers.stub(:hash_for_post_models_path).and_return({})
    url_helpers.stub(:hash_for_authors_path).and_return({})

    double('_routes',
      :url_helpers => url_helpers,
      :url_for => "/mock/path"
    )
  end

  def controller
    env = double('env', :[] => nil)
    request = double('request', :env => env)
    double('controller', :controller_path= => '', :params => {}, :request => request)
  end

  def default_url_options
    {}
  end

  def mock_everything

    # Resource-oriented styles like form_for(@post) will expect a path method for the object,
    # so we're defining some here.
    def post_models_path(*args); "/postmodels/1"; end

    def post_path(*args); "/posts/1"; end
    def posts_path(*args); "/posts"; end
    def new_post_path(*args); "/posts/new"; end

    def author_path(*args); "/authors/1"; end
    def authors_path(*args); "/authors"; end
    def new_author_path(*args); "/authors/new"; end
    
    # Returns the array for Rails 3 and a thing that looks looks like an 
    # association proxy for Rails 4+
    def author_array_or_scope(the_array = [@fred, @bob])
      if ::Formtastic::Util.rails3?
        the_array
      else
        MockScope.new(the_array)
      end
    end
    
    @fred = ::Author.new
    @fred.stub(:class).and_return(::Author)
    @fred.stub(:to_label).and_return('Fred Smith')
    @fred.stub(:login).and_return('fred_smith')
    @fred.stub(:age).and_return(27)
    @fred.stub(:id).and_return(37)
    @fred.stub(:new_record?).and_return(false)
    @fred.stub(:errors).and_return(double('errors', :[] => nil))
    @fred.stub(:to_key).and_return(nil)
    @fred.stub(:persisted?).and_return(nil)
    @fred.stub(:name).and_return('Fred')

    @bob = ::Author.new
    @bob.stub(:to_label).and_return('Bob Rock')
    @bob.stub(:login).and_return('bob')
    @bob.stub(:age).and_return(43)
    @bob.stub(:created_at)
    @bob.stub(:id).and_return(42)
    @bob.stub(:posts).and_return([])
    @bob.stub(:post_ids).and_return([])
    @bob.stub(:new_record?).and_return(false)
    @bob.stub(:errors).and_return(double('errors', :[] => nil))
    @bob.stub(:to_key).and_return(nil)
    @bob.stub(:persisted?).and_return(nil)
    @bob.stub(:name).and_return('Bob')

    @james = ::Author.new
    @james.stub(:to_label).and_return('James Shock')
    @james.stub(:login).and_return('james')
    @james.stub(:age).and_return(38)
    @james.stub(:id).and_return(75)
    @james.stub(:posts).and_return([])
    @james.stub(:post_ids).and_return([])
    @james.stub(:new_record?).and_return(false)
    @james.stub(:errors).and_return(double('errors', :[] => nil))
    @james.stub(:to_key).and_return(nil)
    @james.stub(:persisted?).and_return(nil)
    @james.stub(:name).and_return('James')


    ::Author.stub(:scoped).and_return(::Author)
    ::Author.stub(:find).and_return(author_array_or_scope)
    ::Author.stub(:all).and_return(author_array_or_scope)
    ::Author.stub(:where).and_return(author_array_or_scope)
    ::Author.stub(:human_attribute_name) { |column_name| column_name.humanize }
    ::Author.stub(:human_name).and_return('::Author')
    ::Author.stub(:reflect_on_association) { |column_name| double('reflection', :options => {}, :klass => Post, :macro => :has_many) if column_name == :posts }
    ::Author.stub(:content_columns).and_return([double('column', :name => 'login'), double('column', :name => 'created_at')])
    ::Author.stub(:to_key).and_return(nil)
    ::Author.stub(:persisted?).and_return(nil)

    @hash_backed_author = HashBackedAuthor.new

    # Sometimes we need a mock @post object and some Authors for belongs_to
    @new_post = double('post')
    @new_post.stub(:class).and_return(::Post)
    @new_post.stub(:id).and_return(nil)
    @new_post.stub(:new_record?).and_return(true)
    @new_post.stub(:errors).and_return(double('errors', :[] => nil))
    @new_post.stub(:author).and_return(nil)
    @new_post.stub(:author_attributes=).and_return(nil)
    @new_post.stub(:authors).and_return(author_array_or_scope([@fred]))
    @new_post.stub(:authors_attributes=)
    @new_post.stub(:reviewer).and_return(nil)
    @new_post.stub(:main_post).and_return(nil)
    @new_post.stub(:sub_posts).and_return([]) #TODO should be a mock with methods for adding sub posts
    @new_post.stub(:to_key).and_return(nil)
    @new_post.stub(:to_model).and_return(@new_post)
    @new_post.stub(:persisted?).and_return(nil)
    @new_post.stub(:model_name){ @new_post.class.model_name}

    @freds_post = double('post')
    @freds_post.stub(:to_ary)
    @freds_post.stub(:class).and_return(::Post)
    @freds_post.stub(:to_label).and_return('Fred Smith')
    @freds_post.stub(:id).and_return(19)
    @freds_post.stub(:title).and_return("Hello World")
    @freds_post.stub(:author).and_return(@fred)
    @freds_post.stub(:author_id).and_return(@fred.id)
    @freds_post.stub(:authors).and_return([@fred])
    @freds_post.stub(:author_ids).and_return([@fred.id])
    @freds_post.stub(:new_record?).and_return(false)
    @freds_post.stub(:errors).and_return(double('errors', :[] => nil))
    @freds_post.stub(:to_key).and_return(nil)
    @freds_post.stub(:persisted?).and_return(nil)
    @freds_post.stub(:model_name){ @freds_post.class.model_name}
    @freds_post.stub(:to_model).and_return(@freds_post)
    @fred.stub(:posts).and_return(author_array_or_scope([@freds_post]))
    @fred.stub(:post_ids).and_return([@freds_post.id])

    ::Post.stub(:scoped).and_return(::Post)
    ::Post.stub(:human_attribute_name) { |column_name| column_name.humanize }
    ::Post.stub(:human_name).and_return('Post')
    ::Post.stub(:reflect_on_all_validations).and_return([])
    ::Post.stub(:reflect_on_validations_for).and_return([])
    ::Post.stub(:reflections).and_return({})
    ::Post.stub(:reflect_on_association) { |column_name|
      case column_name
      when :author, :author_status
        mock = double('reflection', :options => {}, :klass => ::Author, :macro => :belongs_to)
        mock.stub(:[]).with(:class_name).and_return("Author")
        mock
      when :reviewer
        mock = double('reflection', :options => {:class_name => 'Author'}, :klass => ::Author, :macro => :belongs_to)
        mock.stub(:[]).with(:class_name).and_return("Author")
        mock
      when :authors
        double('reflection', :options => {}, :klass => ::Author, :macro => :has_and_belongs_to_many)
      when :sub_posts
        double('reflection', :options => {}, :klass => ::Post, :macro => :has_many)
      when :main_post
        double('reflection', :options => {}, :klass => ::Post, :macro => :belongs_to)
      when :mongoid_reviewer
        ::MongoidReflectionMock.new('reflection',
             :options => Proc.new { raise NoMethodError, "Mongoid has no reflection.options" },
             :klass => ::Author, :macro => :referenced_in, :foreign_key => "reviewer_id") # custom id
      end
    }
    ::Post.stub(:find).and_return(author_array_or_scope([@freds_post]))
    ::Post.stub(:all).and_return(author_array_or_scope([@freds_post]))
    ::Post.stub(:where).and_return(author_array_or_scope([@freds_post]))
    ::Post.stub(:content_columns).and_return([double('column', :name => 'title'), double('column', :name => 'body'), double('column', :name => 'created_at')])
    ::Post.stub(:to_key).and_return(nil)
    ::Post.stub(:persisted?).and_return(nil)
    ::Post.stub(:to_ary)

    ::MongoPost.stub(:human_attribute_name) { |column_name| column_name.humanize }
    ::MongoPost.stub(:human_name).and_return('MongoPost')
    ::MongoPost.stub(:associations).and_return({
      :sub_posts => double('reflection', :options => {:polymorphic => true}, :klass => ::MongoPost, :macro => :has_many),
      :options => []
    })
    ::MongoPost.stub(:find).and_return(author_array_or_scope([@freds_post]))
    ::MongoPost.stub(:all).and_return(author_array_or_scope([@freds_post]))
    ::MongoPost.stub(:where).and_return(author_array_or_scope([@freds_post]))
    ::MongoPost.stub(:to_key).and_return(nil)
    ::MongoPost.stub(:persisted?).and_return(nil)
    ::MongoPost.stub(:to_ary)
    ::MongoPost.stub(:model_name).and_return( double(:model_name_mock, :singular => "post", :plural => "posts", :param_key => "post", :route_key => "posts") )

    @new_mm_post = double('mm_post')
    @new_mm_post.stub(:class).and_return(::MongoPost)
    @new_mm_post.stub(:id).and_return(nil)
    @new_mm_post.stub(:new_record?).and_return(true)
    @new_mm_post.stub(:errors).and_return(double('errors', :[] => nil))
    @new_mm_post.stub(:title).and_return("Hello World")
    @new_mm_post.stub(:sub_posts).and_return([]) #TODO should be a mock with methods for adding sub posts
    @new_mm_post.stub(:to_key).and_return(nil)
    @new_mm_post.stub(:to_model).and_return(@new_mm_post)
    @new_mm_post.stub(:persisted?).and_return(nil)
    @new_mm_post.stub(:model_name).and_return(::MongoPost.model_name)

    @mock_file = double('file')
    Formtastic::FormBuilder.file_methods.each do |method|
      @mock_file.stub(method).and_return(true)
    end

    @new_post.stub(:title)
    @new_post.stub(:email)
    @new_post.stub(:url)
    @new_post.stub(:phone)
    @new_post.stub(:search)
    @new_post.stub(:to_ary)
    @new_post.stub(:body)
    @new_post.stub(:published)
    @new_post.stub(:publish_at)
    @new_post.stub(:created_at)
    @new_post.stub(:secret).and_return(1)
    @new_post.stub(:url)
    @new_post.stub(:email)
    @new_post.stub(:color)
    @new_post.stub(:search)
    @new_post.stub(:phone)
    @new_post.stub(:time_zone)
    @new_post.stub(:category_name)
    @new_post.stub(:allow_comments).and_return(true)
    @new_post.stub(:answer_comments)
    @new_post.stub(:country)
    @new_post.stub(:country_subdivision)
    @new_post.stub(:country_code)
    @new_post.stub(:document).and_return(@mock_file)
    @new_post.stub(:column_for_attribute).with(:meta_description).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:title).and_return(double('column', :type => :string, :limit => 50))
    @new_post.stub(:column_for_attribute).with(:body).and_return(double('column', :type => :text))
    @new_post.stub(:column_for_attribute).with(:published).and_return(double('column', :type => :boolean))
    @new_post.stub(:column_for_attribute).with(:publish_at).and_return(double('column', :type => :date))
    @new_post.stub(:column_for_attribute).with(:time_zone).and_return(double('column', :type => :string))
    @new_post.stub(:column_for_attribute).with(:allow_comments).and_return(double('column', :type => :boolean))
    @new_post.stub(:column_for_attribute).with(:author).and_return(double('column', :type => :integer))
    @new_post.stub(:column_for_attribute).with(:country).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:country_subdivision).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:country_code).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:email).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:color).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:url).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:phone).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:search).and_return(double('column', :type => :string, :limit => 255))
    @new_post.stub(:column_for_attribute).with(:document).and_return(nil)

    @new_post.stub(:author).and_return(@bob)
    @new_post.stub(:author_id).and_return(@bob.id)

    @new_post.stub(:reviewer).and_return(@fred)
    @new_post.stub(:reviewer_id).and_return(@fred.id)

    # @new_post.should_receive(:publish_at=).at_least(:once)
    @new_post.stub(:publish_at=)
    # @new_post.should_receive(:title=).at_least(:once)
    @new_post.stub(:title=)
    @new_post.stub(:main_post_id).and_return(nil)

  end

  def self.included(base)
    base.class_eval do

      attr_accessor :output_buffer

      def protect_against_forgery?
        false
      end

      def _helpers
        FakeHelpersModule
      end

    end
  end

  def with_config(config_method_name, value, &block)
    old_value = Formtastic::FormBuilder.send(config_method_name)
    Formtastic::FormBuilder.send(:"#{config_method_name}=", value)
    yield
    Formtastic::FormBuilder.send(:"#{config_method_name}=", old_value)
  end
  
  class ToSMatcher
    def initialize(str)
      @str=str.to_s
    end
    
    def matches?(value)
      value.to_s==@str
    end
    
    def failure_message_for_should
      "Expected argument that converted to #{@str}"
    end
  end
  
  def errors_matcher(method)
    # In edge rails (Rails 4) tags store method_name as a string and index the errors object using a string
    # therefore allow stubs to match on either string or symbol.  The errors object calls to_sym on all index 
    # accesses so @object.errors[:abc] is equivalent to @object.errors["abc"]
    if Rails::VERSION::MAJOR == 4
      ToSMatcher.new(method)
    else
      method
    end
  end
end

class ::ActionView::Base
  include Formtastic::Helpers::FormHelper
end

::ActiveSupport::Deprecation.silenced = false

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  config.before(:each) do
    Formtastic::Localizer.cache.clear!    
  end
  
  config.before(:all) do
    DeferredGarbageCollection.start unless ENV["DEFER_GC"] == "false"
  end
  config.after(:all) do
    DeferredGarbageCollection.reconsider unless ENV["DEFER_GC"] == "false"    
  end
end
