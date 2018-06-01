require "spec_helper"
require "usable/persisted"

describe Usable::Persisted do
  subject { Class.new(super_class) { extend ::Usable::Persisted } }

  let(:super_class) { Class.new }
  let(:mod) do
    Module.new do
      def versions
        "Saving #{usables.max_versions} versions to #{usables.table_name} table"
      end

      def destroy_version
        "destroying version"
      end

      def latest_version
        'here i am'
      end

      const_set :TEST_CONST, 1
      const_set :InnerTestClass, Class.new
    end
  end

  let(:config_file) { "#{config_dir}/testclass.yml" }
  let(:config_dir) { File.expand_path('../../../../lib/usable', __FILE__) }

  # We require the class to have a name for persisted to work
  before do
    Object.const_set(:TestClass, subject)
  end

  after do
    Object.send(:remove_const, :TestClass)
    FileUtils.rm(config_file)
  end

  it 'sets uses the custom directory' do
    subject.usable mod, persisted: true
    subject.new.random = 101
    expect(subject.new._config_file).to match %r|usable/lib/usable/testclass\.yml|
  end

  it 'persists usables the YAML file specified in the options' do
    expect {
      subject.new.random = 101
    }.to change { File.exists?(config_file) }.from(false).to(true)
  end

  it "saves values to the object's usables" do
    expect {
      subject.new.random = 101
    }.to change { subject.usables.random }.from(nil).to(101)
  end

  it 'supports checking if the object has an attribute' do
    expect {
      subject.new.random = 101
    }.to change { subject.new.has?(:random) }.from(false).to(true)
  end
end
