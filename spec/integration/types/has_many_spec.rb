require 'spec_helper'

describe CustomFields::Types::HasMany do

  before(:each) do
    @blog     = create_blog
    @post_1   = @blog.posts.create :title => 'Hello world', :body => 'Lorem ipsum...'
    @post_2   = @blog.posts.create :title => 'High and Dry', :body => 'Lorem ipsum...'
    @post_3   = @blog.posts.create :title => 'Nude', :body => 'Lorem ipsum...'
  end

  describe 'a new author' do

    before(:each) do
      @author = @blog.people.build :name => 'John Doe'
    end

    it 'sets the posts' do
      save_author @author, [@post_1, @post_2]
      @author.posts.map(&:title).should == ['Hello world', 'High and Dry']
    end

    it 'increments position thanks the belongs_to relationship' do
      save_author @author, [@post_1, @post_2]
      @post_1.reload.position_in_author.should == 1
      @post_2.reload.position_in_author.should == 2
    end

    it 'retrieves posts based on their position' do
      save_author @author, [@post_1.reload, @post_2.reload]
      @post_1.reload.update_attributes :position_in_author => 4
      @author = Person.find(@author._id)
      @author.posts.map(&:title).should == ['High and Dry', 'Hello world']
    end

  end

  describe 'an existing author' do

    before(:each) do
      @author = @blog.people.create :name => 'John Doe'
      save_author @author, [@post_1, @post_2]
      @author = Person.find(@author._id)
    end

    it 'returns the titles of the posts' do
      @author.posts.map(&:title).should == ['Hello world', 'High and Dry']
    end

    it 'sets new posts instead' do
      @author.posts.clear
      save_author @author, [@post_3]
      @author = Person.find(@author._id)
      @author.posts.map(&:title).should == ['Nude']
    end

  end

  def create_blog
    Blog.new(:name => 'My personal blog').tap do |blog|
      blog.posts_custom_fields.build :label => 'Author', :type => 'belongs_to', :class_name => 'Person'
      blog.people_custom_fields.build :label => 'Posts', :type => 'has_many', :class_name => "Post#{blog._id}", :inverse_of => 'author'
      blog.save & blog.reload
    end
  end

  def save_author(author, posts)
    posts.each { |post| post.author = author; post.save }
    # author.posts.concat(posts) # does not work
    author.save
  end
end