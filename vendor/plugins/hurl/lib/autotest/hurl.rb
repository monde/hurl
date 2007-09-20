require 'autotest'

class Autotest::Hurl < Autotest

  def initialize # :nodoc:
    super
    @exceptions = %r%\.(log|db|txt|rhtml|svn)$%

    @test_mappings = {
      %r%^test/fixtures/([^_]+)_.*s\.yml% => proc { |_, m|
        "test/#{m[1]}_test.rb"
      },
      %r%^hurl/(.+)\.rb$% => proc { |_, m|
        ["test/test_#{m[1]}.rb"]
      },
      %r%^hurl.rb$% => proc { |_, m|
        ["test/test_hurl.rb"]
      },
      %r%^test/.*rb$% => proc { |filename, m|
        filename
      }
    }
  end

  def tests_for_file(filename)
    super.select { |f| @files.has_key? f }
  end

end
