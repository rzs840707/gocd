require "test_helper"
require "representable/object"

class ObjectTest < MiniTest::Spec
  Song  = Struct.new(:title, :album)
  Album = Struct.new(:name, :songs)

  representer!(module: Representable::Object) do
    property :title

    property :album, instance: lambda { |fragment, *| fragment.name.upcase!; fragment } do
      property :name

      collection :songs, instance: lambda { |fragment, *| fragment.title.upcase!; fragment } do
        property :title
      end
    end
    # TODO: collection
  end

  let (:source) { Song.new("The King Is Dead", Album.new("Ruiner", [Song.new("In Vino Veritas II")])) }
  let (:target) { Song.new }

  it do
    representer.prepare(target).from_object(source)

    target.title.must_equal "The King Is Dead"
    target.album.name.must_equal "RUINER"
    target.album.songs[0].title.must_equal "IN VINO VERITAS II"
  end

  # ignore nested object when nil
  it do
    representer.prepare(Song.new("The King Is Dead")).from_object(Song.new)

    target.title.must_equal nil # scalar property gets overridden when nil.
    target.album.must_equal nil # nested property stays nil.
  end

  # to_object
  describe "#to_object" do
    representer!(module: Representable::Object) do
      property :title

      property :album, render_filter: lambda { |object, *| object.name = "Live"; object } do
        property :name

        collection :songs, render_filter: lambda { |object, *| object[0].title = 1; object } do
          property :title
        end
      end
    end

    it do
      representer.prepare(source).to_object
      source.album.name.must_equal "Live"
      source.album.songs[0].title.must_equal 1
    end
  end
end