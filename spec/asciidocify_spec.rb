require "ostruct"
require_relative "../_ext/asciidocify.rb"

class TestADoc 
    include AsciiDoc
end

describe AsciiDoc do

  it "should be able to render string to asciidoc" do
    
    content = "* 1 \n* 2"

    rendered = TestADoc.new.asciidocify content

    rendered.should match /<li>/

  end

  it "should be able to render source to asciidoc" do
    
    content = "public void test() {}"

    rendered = TestADoc.new.sourcify content
    rendered.should match /<code/

  end

  it "should be able to render source to asciidoc with outline" do
    
    content = <<-eos
public void test() {} <1> Test\n

public void test() {} <2> Wee
eos

    rendered = TestADoc.new.sourcify content
    rendered.should match /<code/
    rendered.should match /<p>Wee/

  end

  it "should be able to render include source from site" do
    
    content = <<-eos
Some text 
include::TestClass[]
eos
    sample = OpenStruct.new
    sample.sources = [] << OpenStruct.new(
        {
          "name" => "TestClass",
          "content" => "public void test() {}"
        })

    rendered = TestADoc.new.asciidocify content, sample
    rendered.should match /<code/
    rendered.should match /public void/

  end

end