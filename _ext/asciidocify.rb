require "asciidoctor"
require 'asciidoctor/extensions'

module AsciiDoc

  Asciidoctor::Extensions.register do |document|
    #unless document.attributes["sample"].nil? or document.attributes["sample"].empty?
      include_processor SiteIncludeProcessor
    #end
  end

  def asciidocify(content, sample = {})
    Asciidoctor.render(content, {:attributes => {"sample" => sample}})
  end

  def sourcify(source, lang = "java", render = true)
    parsed = outlinify(source)
    block = ''
    block += %Q([source,#{lang}]\n)
    block += %Q(----\n)
    block += %Q(#{parsed[:code]}\n)
    block += %Q(----\n)
    parsed[:outlines].each {|x|
      block += %Q(#{x}\n)
    }

    return asciidocify block if render
    return block
  end

  def outlinify(source)
    outlines = []
    code = source.lines.collect{
      |x|
      new_line = x
      if new_line =~ /(.*)(<[0-9]+>) (.*)/
        outlines << "#{$2} #{$3}"
        new_line = "#{$1}#{$2}\n"
      end
      new_line
    }.join()
    {:outlines => outlines, :code => code}
  end

end

class SiteIncludeProcessor < Asciidoctor::Extensions::IncludeProcessor
  include AsciiDoc
  
  def handles? target
    true
  end

  def process reader, target, attributes
    sample = @document.attributes["sample"]
    target_file = target
    target_method = nil

    if target =~ /(.*)#(.*)/
      target_file = $1
      target_method = $2
    end

    file = sample.sources.find {|x| x.name.eql? target_file} unless sample.sources.nil?
    file = sample.tests.find {|x| x.name.eql? target_file} if file.nil? and !sample.tests.nil?

    if file.nil?
      return reader.push_include "WARNING: #{target} not found", target, target, 1, attributes
    end

    source = file.content
    unless target_method.nil?
      method = file.children.find{|x| x.name.eql? target_method} unless file.children.nil?
      if method.nil?
        return reader.push_include "WARNING: Method in #{target} not found", target, target, 1, attributes
      end
      source = method.content
    end

    block = sourcify source, "java", false 
    reader.push_include block, target, target, 1, attributes
  end
end
