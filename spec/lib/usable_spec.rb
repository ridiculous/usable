require "spec_helper"

describe Usable do
  subject { Class.new { extend ::Usable } }

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
    end
  end

  let(:spec_mod) do
    Module.new do
      def destroy_version
        'nothing here'
      end

      def update_version
        'defined on spec'
      end
    end
  end

  let(:class_mod) do
    Module.new do
      def from_class_mod
        'defined on class'
      end
    end
  end

  let(:instance_mod) do
    Module.new do
      def from_instance_mod
        'defined as instance method'
      end
    end
  end

  after(:each) { subject.usables = nil }

  context 'when extending a module with Usable' do
    it 'defines +config+ which delegates to +usables+ for setting configuration' do
      spec_mod.extend Usable
      spec_mod.config do
        language :en
      end
      spec_mod.config.country = 'US'
      expect(spec_mod.usables.country).to eq 'US'
      expect(spec_mod.usables.language).to eq :en
      expect(spec_mod.config).to be spec_mod.usables
    end

    context 'when the module already defines +config+' do
      before do
        def spec_mod.config
          'existing config'
        end
      end

      it 'does not overwrite the existing method' do
        spec_mod.extend Usable
        expect(spec_mod.config).to eq 'existing config'
      end
    end
  end

  describe "#usables" do
    it "returns a usable config" do
      expect(subject.usables).to be_a Usable::Config
    end
  end

  describe "#usable" do
    it 'returns self' do
      expect(subject.usable(mod)).to be subject
    end

    context 'when given multiple modules' do
      before do
        mod.extend Usable
        mod.config do
          versions_size 10
        end
        instance_mod.extend Usable
        instance_mod.config do
          instance_size 15
        end
        subject.usable mod, instance_mod
      end

      it 'uses all the modules' do
        expect(subject.new).to respond_to(:versions)
        expect(subject.new).to respond_to(:from_instance_mod)
        expect(subject.usables.versions_size).to eq 10
        expect(subject.usables.instance_size).to eq 15
      end
    end

    context "when block_given?" do
      it "yields @usables to the given block" do
        expect(subject.usables).to_not respond_to(:max_versions)
        subject.usable(mod) { max_versions 10 }
        expect(subject.usables).to respond_to(:max_versions)
        expect(subject.usables.max_versions).to eq(10)
      end

      it "uses the usables in the method calls" do
        subject.usable mod do
          table_name 'versions'
          max_versions 10
        end
        expect(subject.new.versions).to eq "Saving 10 versions to versions table"
      end
    end

    context "when options are given" do
      it "defines the given options as usable settings" do
        subject.usable mod, table_name: 'versions' do
          max_versions 10
        end
        expect(subject.new.versions).to eq "Saving 10 versions to versions table"
      end
    end

    context 'when given the :method option' do
      before do
        subject.class_eval do
          def destroy_version
            'no-op'
          end
        end
      end

      it 'extends the target const using the specified :method' do
        subject.usable mod, method: :prepend
        expect(subject.new.destroy_version).to eq "destroying version"
      end
    end

    context 'when given the :only option' do
      it 'defines the specified method' do
        subject.usable mod, only: :destroy_version
        expect(subject.new.destroy_version).to eq "destroying version"
        expect(subject.new).to_not respond_to :versions
      end

      it 'defines the specified methods' do
        subject.usable mod, only: [:destroy_version, :versions]
        expect(subject.new.destroy_version).to eq "destroying version"
        expect(subject.new.versions).to match(/saving/i)
      end

      it 'stubs out the other methods to return nil' do
        subject.usable mod, only: :destroy_version
        expect(subject.new.destroy_version).to eq "destroying version"
        expect(subject.new).to_not respond_to :versions
      end

      context 'when the given module has a ClassMethods mod defined' do
        before do
          mod.const_set :ClassMethods, class_mod
        end

        after do
          mod.send :remove_const, :ClassMethods
        end

        it 'defines the class methods on the target' do
          expect(subject).to_not respond_to(:from_class_mod)
          expect(subject.new).to_not respond_to(:from_class_mod)
          subject.usable mod
          expect(subject.new).to_not respond_to(:from_class_mod)
          expect(subject.from_class_mod).to eq 'defined on class'
        end
      end

      context 'when the given module has a InstanceMethods mod defined' do
        before do
          mod.const_set :InstanceMethods, instance_mod
        end

        after do
          mod.send :remove_const, :InstanceMethods
        end

        it 'defines the class methods on the target' do
          expect(subject).to_not respond_to(:from_instance_mod)
          expect(subject.new).to_not respond_to(:from_instance_mod)
          subject.usable mod
          expect(subject).to_not respond_to(:from_instance_mod)
          expect(subject.new).to respond_to(:from_instance_mod)
          expect(subject.new.from_instance_mod).to eq 'defined as instance method'
        end
      end
    end

    context 'when the given module has defined a +usables+' do
      before do
        mod.extend described_class
        mod.usables[:key] = 'secret'
      end

      it 'copies the usable config settings over to the subject' do
        expect { subject.usable mod }.to change { subject.usables[:key] }.from(nil).to('secret')
      end

      context 'with multiple usable mods', block_specs: true do
        before do
          spec_mod.extend described_class
          spec_mod.config do
            model { Usable::ModExtender }
            cache_key 'specs:mods'
          end
        end

        it "merges the given usables with the subject's" do
          subject.usable mod
          subject.usable spec_mod
          expect(spec_mod.usables.model).to eq(Usable::ModExtender)
          expect(subject.usables.model).to eq(Usable::ModExtender)
        end

        it "maintains the laziness of block specs" do
          n = 10
          mod.usables.foo { n }
          subject.usable mod
          subject.usable spec_mod
          n += 5
          expect(mod.usables.foo).to eq 15
          n += 5
          # it doesn't change cause it's memoized
          expect(mod.usables.foo).to eq 15
          # should load for the first time
          expect(subject.usables.foo).to eq 20
          n += 5
          # it doesn't change cause it's memoized
          expect(subject.usables.foo).to eq 20
        end

        context 'when block specs are overridden' do
          before do
            mod.usables.foo { :ok }
            spec_mod.usables.foo { :error }
          end

          it 'returns the value for the last spec added' do
            subject.usable spec_mod
            subject.usable mod
            expect(subject.usables.foo).to eq :ok
          end
        end
      end

      context "when the subject is given settings with the same name as the module's setting" do
        it 'uses the given settings' do
          expect {
            subject.usable mod do
              key 'public'
            end
          }.to change { subject.usables[:key] }.from(nil).to('public')
        end
      end
    end
  end

  describe 'instance level config access' do
    it 'should expose +usables+ on the instance' do
      expect(subject.new.usables).to be subject.usables
    end
  end

  describe '#available_methods' do
    it 'returns the list of unbound methods we defined on the target' do
      expect(subject.usables.available_methods).to be_empty
      subject.usable mod
      expect(subject.usables.available_methods.keys.sort).to eq [:destroy_version, :latest_version, :versions]
      expect(subject.usables.available_methods[:destroy_version]).to be_kind_of UnboundMethod
    end
  end

  describe 'Naming modules' do
    before { Object.const_set :Subject, subject }
    after { Object.send :remove_const, :Subject }

    context 'when given the module is anonymous' do
      it 'generates a name using a timestamp' do
        expect(ancestors[1].to_s).to_not match /Subject::UsableMod\d{10}Used/
        Subject.usable mod
        expect(ancestors[1].to_s).to match /Subject::UsableMod\d{10}Used/
      end
    end

    context 'when given the module has a name' do
      before { Object.const_set :TestMod, mod }
      after { Object.send :remove_const, :TestMod }

      context "when module's methods is mutated by the :only option" do
        it 'appends "Used" to the name of the original module' do
          expect {
            Subject.usable TestMod, only: :destroy_version
          }.to change { ancestors }.to include 'Subject::TestModUsed'
          assert_index_of_mod 'Subject::TestModUsed', 1
        end

        it 'does not mutate the original module' do
          expect {
            Subject.usable TestMod, only: :destroy_version
          }.to_not change { TestMod.instance_methods(false) }
        end

        it 'scopes the config to a method named after the module on @usables' do
          Subject.usable TestMod do
            language :en
          end
          expect(subject.usables.test_mod).to be_a(Usable::Config)
          expect(subject.usables.test_mod.language).to eq :en
        end

        context 'when including modules with the same settings' do
          before { Object.const_set :OtherMod, class_mod }
          after { Object.send :remove_const, :OtherMod }

          before do
            Subject.usable TestMod do
              language :en
            end
            Subject.usable OtherMod do
              language :fr
            end
          end

          it 'scopes the settings to the module name' do
            expect(subject.usables.test_mod.language).to be :en
            expect(subject.usables.other_mod.language).to be :fr
          end

          it 'gives defines the settings globally using the last value' do
            expect(subject.usables.language).to be :fr
          end
        end
      end

      context 'when given the :only option is empty' do
        it 'uses the module name without defining a new constant under Subject' do
          expect {
            Subject.usable TestMod
          }.to change { ancestors }.to include 'TestMod'
          assert_index_of_mod 'TestMod', 1
        end
      end
    end

    def assert_index_of_mod(mod_name, expected_index)
      expect(ancestors.index(mod_name)).to eq expected_index
    end

    def ancestors
      Subject.ancestors.map(&:to_s)
    end
  end

  describe '.usable_method' do
    it 'returns a method for the given method bound to the given context' do
      expect(subject.usable_method(subject.new, :latest_version).call).to be nil
      subject.usable mod
      expect(subject.usable_method(subject.new, :latest_version)).to be_a(Method)
      expect(subject.usable_method(subject.new, :latest_version).name).to be :latest_version
      expect(subject.usable_method(subject.new, :latest_version).call).to eq "here i am"
    end

    context 'when the method cannot be found' do
      it 'returns the null method' do
        subject.usable mod
        expect(subject.usable_method(subject.new, :foo)).to be_a(Method)
        expect(subject.usable_method(subject.new, :foo).name).to be :default_method
        expect(subject.usable_method(subject.new, :foo).call).to be nil
      end
    end
  end

  describe '#usable_method' do
    it 'returns a method for the given method bound to the given context' do
      expect(subject.new.usable_method(:latest_version).call).to be nil
      subject.usable mod
      expect(subject.new.usable_method(:latest_version)).to be_a(Method)
      expect(subject.new.usable_method(:latest_version).name).to be :latest_version
      expect(subject.new.usable_method(:latest_version).call).to eq "here i am"
    end

    context 'when the method cannot be found' do
      it 'returns the null method' do
        subject.usable mod
        expect(subject.new.usable_method(:foo)).to be_a(Method)
        expect(subject.new.usable_method(:foo).name).to be :default_method
        expect(subject.new.usable_method(:foo).call).to be nil
      end
    end
  end

  describe 'copying usables when extending a usable module' do
    before do
      mod.extend Usable
      mod.config do
        host 'localhost'
      end
    end

    it 'copies over usables' do
      expect(subject.usables.available_methods).to be_empty
      subject.usable mod, method: :extend
      expect(subject.usables).to respond_to(:host)
      expect(subject.usables.available_methods).to_not be_empty
    end
  end
end
