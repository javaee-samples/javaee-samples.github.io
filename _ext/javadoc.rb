require 'java'
raise "Missing JAVA_HOME, require tools.jar" unless ENV['JAVA_HOME']

$CLASSPATH << "#{ENV['JAVA_HOME']}/lib/tools.jar"

module Java
  module Doc

    def self.parse(source_path, quiet = true, &block)
      context = com.sun.tools.javac.util.Context.new

      options = com.sun.tools.javac.util.Options.instance context
      options.put '-sourcepath', source_path
      options.put '-Xmaxerrs', '1'
      options.put '-Xmaxwarns', '1'
      
      # Silence!!
      out = java.io.PrintWriter.new java.io.StringWriter.new      
      com.sun.tools.javadoc.Messager.preRegister context, "javadoc", out, out, out

      tool = com.sun.tools.javadoc.JavadocTool.make0 context

      sub_packages = com.sun.tools.javac.util.List.of 'org', 'com'
      options_list = com.sun.tools.javac.util.List.nil
      empty = com.sun.tools.javac.util.List.nil
      filter = com.sun.tools.javadoc.ModifierFilter.new com.sun.tools.javadoc.ModifierFilter::ALL_ACCESS

      com.sun.tools.javadoc.DocEnv.instance(context).silent = quiet
      
      root = tool.getRootDocImpl('en', 'ascii', filter, empty, empty, options_list, false, sub_packages, empty, false, false, quiet)

      block.call(root) if block
      return root
    end

  end
end
