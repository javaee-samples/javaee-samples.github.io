require "ostruct"
require_relative "../_ext/asciidocify.rb"

class TestADoc 
    include AsciiDoc
end

describe AsciiDoc do

  it "should be able to render string to asciidoc" do

    content = "* 1 \n* 2"

    rendered = TestADoc.new.asciidocify content

    expect(rendered).to match /<li>/

  end

  it "should be able to render source to asciidoc" do

    content = "public void test() {}"

    rendered = TestADoc.new.sourcify content
    expect(rendered).to match /<code/

  end

  it "should be able to render source to asciidoc with outline" do

    content = <<-eos
public void test() {} <1> Test\n

public void test() {} <2> Wee
eos

    rendered = TestADoc.new.sourcify content
    expect(rendered).to match /<code/
    expect(rendered).to match /<p>Wee/

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
          "path" => "/tmp/TestClass.java",
          "content" => "public void test() {}"
        })

    rendered = TestADoc.new.asciidocify content, sample
    expect(rendered).to match /<code/
    expect(rendered).to match /public void/

  end

  it "should be able to render API as links" do

    content = <<-eos
Some text javax.batch.api.Batchlet even tho
eos
    sample = OpenStruct.new
    sample.sources = [] << OpenStruct.new

    rendered = TestADoc.new.asciidocify content, sample
    expect(rendered).to match /<a/
    expect(rendered).to match /title=/

  end
end