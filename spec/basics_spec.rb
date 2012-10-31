describe "CurlyCurly" do
  def compile_ruby_template(name)
    `ruby curly.rb -t Ruby -i spec/templates/#{name}.curly --no-header -`
  end

  sets = [
    ["the static template", "static"],
    ["templates with a variable", "variable"],
    ["conditional templates", "conditional"]
  ]
  ext = {
    "ruby" => "rb"
  }

  ["ruby"].each do |lang|
    sets.each do |msg, name|
      it "should evaluate #{msg} in #{lang}" do
        compiled = method(:"compile_#{lang}_template").call(name)
        compiled.should eq(File.read("spec/compiled/#{name}.#{ext[lang]}"))
      end
    end
  end
end