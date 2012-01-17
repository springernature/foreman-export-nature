require 'spec_helper'

describe Foreman::Export::NatureRunit::Service do
  subject { Foreman::Export::NatureRunit::Service.new(name, command, target, environment) }

  let(:target)      { Pathname.new('~/').expand_path }
  let(:name)        { "test-service" }
  let(:command)     { "cat foo" }
  let(:environment) { Hash["FOO" => 'bar', "BAZ" => 'bat'] }

  before(:each) do
    subject.stub!(:create_if_missing)
    subject.stub!(:write_file)
  end

  describe ".new" do
    subject { Foreman::Export::NatureRunit::Service }
    it "sets up the class propery" do
      result = subject.new(name, command, target, environment)

      result.target.should == target.join(name).expand_path
      result.active_target.should == target.join('..', '..', 'service', name).expand_path
      result.environment.should == environment
      result.environment_target.should == result.target.join('env').expand_path
      result.command.should == command
    end
  end

  describe "#create!" do
    it "generates a run script to save to disk" do
      subject.stub!(:export_environment!)

      subject.should_receive(:export_run_script!)
      subject.create!
    end

    it "exports the environmnet vars" do
      subject.stub!(:write_file)

      subject.should_receive(:export_environment!)
      subject.create!
    end
  end

  describe "#export_run_script!" do
    let(:fake_content) { "blabla" }

    it "trys to make the needed directory if its missing" do
      subject.should_receive(:create_if_missing).with(subject.target)
      subject.export_run_script!
    end

    it "generates a run script to save to disk" do
      subject.should_receive(:run_script).and_return(fake_content)
      subject.should_receive(:write_file).with(subject.target.join('run'), fake_content)

      subject.export_run_script!
    end

  end

  describe "#run_script" do
    let(:fake_content) { "blabla" }
    let(:erb_template_double) { double('erb_template') }

    it "compiles the template with erb" do
      ERB.should_receive(:new).with(Foreman::Export::NatureRunit::Service.run_template.read).and_return(erb_template_double)
      erb_template_double.should_receive(:result).and_return(fake_content)

      subject.run_script.should == fake_content
    end
  end

  describe "activate!" do
    it "symlinks the service into the 'running' dir" do
      FileUtils.should_receive(:symlink).with(subject.target, subject.active_target)

      subject.activate!
    end
  end

  describe "export_environment!" do
    it "trys to make the needed directory if its missing" do
      subject.should_receive(:create_if_missing).with(subject.environment_target)
      subject.export_environment!
    end

    it "writes the env vars as files inside the services target dir" do
      environment.each do |key,value|
        subject.should_receive(:write_file).with(subject.environment_target.join(key), value)
      end

      subject.export_environment!
    end

  end
end