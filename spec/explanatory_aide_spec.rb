require 'bacon'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'active_support/core_ext/string/inflections'
require 'explanatory_aide'

module ExplanatoryAide
  describe ARGV do
    before do
      @argv = ARGV.new(%w{ --flag --option VALUE ARG1 ARG2 --no-other-flag })
    end

    it "returns the options as a hash" do
      @argv.options.should == {
        'flag' => true,
        'other-flag' => false,
        'option' => 'VALUE'
      }
    end

    it "returns the arguments" do
      @argv.arguments.should == %w{ ARG1 ARG2 }
    end

    it "returns a flag and deletes it" do
      @argv.flag?('flag').should == true
      @argv.flag?('other-flag').should == false
      @argv.flag?('option').should == nil
      @argv.remainder.should == %w{ --option VALUE ARG1 ARG2 }
    end

    it "returns an option and deletes it" do
      @argv.option('flag').should == nil
      @argv.option('other-flag').should == nil
      @argv.option('option').should == 'VALUE'
      @argv.remainder.should == %w{ --flag ARG1 ARG2 --no-other-flag }
    end

    it "returns the first argument and deletes it" do
      @argv.shift_argument.should == 'ARG1'
      @argv.remainder.should == %w{ --flag --option VALUE ARG2 --no-other-flag }
    end
  end
end

module Fixture
  class Command < ExplanatoryAide::Command
    def self.options
      [
        ['--verbose', 'Print more info'],
        ['--help',    'Print help banner'],
      ]
    end

    class SpecFile < Command
      class Create < SpecFile
        def self.description
          'Creates a spec file stub.'
        end

        attr_reader :spec
        def initialize(argv)
          @spec = argv.shift_argument
          super
        end

        def run
          # This command actully does something.
        end
      end

      class Lint < SpecFile
        def self.description
          'Checks a spec file.'
        end

        def self.options
          [['--only-errors', 'Skip warnings']].concat(super)
        end

        class Repo < Lint
        end
      end
    end
  end
end

module ExplanatoryAide
  describe Command do
    it "registers the subcommand classes" do
      Fixture::Command.subcommands.map(&:command).should == %w{ spec-file }
      Fixture::Command::SpecFile.subcommands.map(&:command).should == %w{ create lint }
      Fixture::Command::SpecFile::Create.subcommands.map(&:command).should == []
      Fixture::Command::SpecFile::Lint.subcommands.map(&:command).should == %w{ repo }
    end

    it "tries to match a subclass for each of the subcommands" do
      Fixture::Command.parse(%w{ spec-file }).should.be.instance_of Fixture::Command::SpecFile
      Fixture::Command.parse(%w{ spec-file lint }).should.be.instance_of Fixture::Command::SpecFile::Lint
      Fixture::Command.parse(%w{ spec-file lint repo }).should.be.instance_of Fixture::Command::SpecFile::Lint::Repo
    end

    # TODO might be more the task of the application?
    #it "raises a Help exception when run without any subcommands" do
      #lambda { Fixture::Command.run([]) }.should.raise Command::Help
    #end

    it "does not raise if one of the subcommands consumes arguments" do
      subcommand = Fixture::Command.parse(%w{ spec-file create AFNetworking })
      subcommand.spec.should == 'AFNetworking'
    end

    it "raises a Help exception when created with an invalid subcommand" do
      lambda { Fixture::Command.parse(%w{ unknown }) }.should.raise Command::Help
      lambda { Fixture::Command.parse(%w{ spec-file unknown }) }.should.raise Command::Help
    end

    it "raises a Help exception when running a command that does not itself implement #run" do
      lambda { Fixture::Command.run(%w{ spec-file create }) }.should.not.raise
      lambda { Fixture::Command.run(%w{ spec-file }) }.should.raise Command::Help
    end
  end

  describe Command::Help, "formatting" do
    it "returns the subcommands" do
      Command::Help.new(Fixture::Command::SpecFile, nil).commands.should == <<-COMMANDS.rstrip
    $ spec-file create

      Creates a spec file stub.

    $ spec-file lint

      Checks a spec file.
COMMANDS
    end

    it "returns the options, for all ancestor commands, aligned so they're all aligned with the largest option name" do
      Command::Help.new(Fixture::Command::SpecFile, nil).options.should == <<-OPTIONS.rstrip
    --verbose   Print more info
    --help      Print help banner
OPTIONS
      Command::Help.new(Fixture::Command::SpecFile::Lint::Repo, nil).options.should == <<-OPTIONS.rstrip
    --only-errors   Skip warnings
    --verbose       Print more info
    --help          Print help banner
OPTIONS
    end
  end
end
