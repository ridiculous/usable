require "spec_helper"
require "usable/persistence"

describe Usable::Persistence do
  subject { Class.new(super_class) { extend ::Usable::Persistence } }

  let(:super_class) { Class.new }
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

  it 'supports hashes as attributes' do
    obj      = subject.new
    obj.data = { data: { type: "users", attributes: { "name" => "Ryan" } } }
    # Setting it to nil on the underlying +usables+ object should force the value to be loaded from file
    obj.usables.data = nil
    expect(obj.data).to eq(data: { type: "users", attributes: { "name" => "Ryan" } })
  end

  context 'Anonymous class extension' do
    let(:config_file) { "#{config_dir}/usable.yml" }

    it 'works just as well with anonymous classes' do
      anon        = Class.new { extend ::Usable::Persistence }.new
      anon.random = 290
      expect(anon.random).to eq 290
      expect(anon._config_file).to include("usable/lib/usable/usable.yml")
    end
  end
end
