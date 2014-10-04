#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "load" do

	before do
		delete_project
		create_project
	end

	after do
		delete_project
	end

	it "should raise an error unless PROJECT is a valid project directory" do
		delete_project
		expect { Glyph.run! 'load:all' }.to raise_error
	end

	it "[macros] should load macro definitions" do
		expect { Glyph.run! 'load:macros'}.not_to raise_error
		expect(Glyph::MACROS[:note].blank?).to eq(false)
		expect(Glyph::MACROS[:"#"].blank?).to eq(false)
	end

	it "[macros] should be able to load only core macros" do
		language 'core'
		expect(output_for("$:[options.macro_set|glyph]").blank?).to eq(true)
		expect(Glyph['options.macro_set']).to eq('glyph')
	end
	
	it "[macros] should be able to load only filter macros" do
		language 'filters'
		expect(output_for("textile[*test*]")).to eq("<p><strong>test</strong></p>")
	end

	it "[config] should load configuration files and apply overrides" do
    Glyph.config_refresh
		expect { Glyph.run! 'load:config'}.not_to raise_error
		Glyph['system.quiet'] = true
		expect(Glyph::PROJECT_CONFIG.blank?).to eq(false)
		expect(Glyph::SYSTEM_CONFIG.blank?).to eq(false)
		expect(Glyph['system.structure.headers'].class.to_s).to eq("Array")
	end

	it "[macros] should load HTML macros as well when generating web output" do
		Glyph['document.output'] = 'web'
		Glyph.run! 'load:macros'
		expect(Glyph::MACROS[:section].blank?).to eq(false)
	end

	it "[layouts] should load layouts" do
		Glyph['document.output'] = 'web'
		Glyph.run! 'load:macros'
		expect(Glyph::MACROS[:"layout/topic"].blank?).to eq(false)
	end

	it "[tasks] should load tasks" do
		reset_quiet
		file_copy Glyph::PROJECT/"../files/custom_tasks.rake", Glyph::PROJECT/"lib/tasks/custom_tasks.rake"
		Glyph.run 'load:all'
		expect(stdout_for { Glyph.run 'custom:hello'}).to eq("Hello, World!\n")
	end

	it "[commands] should load tasks" do
		reset_quiet
		file_copy Glyph::PROJECT/"../files/custom_command.rb", Glyph::PROJECT/"lib/commands/custom_command.rb"
		Glyph.run 'load:all'
		expect(run_command(['hello'])).to eq("Hello, World!\n")
	end

end
