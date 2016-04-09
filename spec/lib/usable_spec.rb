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
    it 'returns an instance of ModExtender' do
      expect(subject.usable(mod)).to be_a(Usable::ModExtender)
    end

    context "when block_given?" do
      it "yields @usables to the given block" do
        expect {
          subject.usable mod do
            max_versions 10
          end
        }.to change(subject.usables, :max_versions).from(nil).to(10)
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

      context 'when the given module has a UsableSpec defined' do
        before do
          mod.const_set :UsableSpec, spec_mod
          mod.const_set :OtherMod, class_mod
        end

        after do
          mod.send :remove_const, :UsableSpec
          mod.send :remove_const, :OtherMod
        end

        context 'when the :only option is in effect' do
          it 'stubs out all but the methods specified except for those on the parent module' do
            subject.usable mod, only: :destroy_version
            expect(subject.new).to_not respond_to :update_version
            expect(subject.new.versions).to be_kind_of String
            expect(subject.new.latest_version).to eq "here i am"
          end
        end

        it 'defines instance methods on from the spec on the target class' do
          expect(subject.new).to_not respond_to(:update_version)
          subject.usable mod
          expect(subject.new.update_version).to eq 'defined on spec'
        end

        it 'defines methods from the main module as well' do
          subject.usable mod
          expect(subject.new.latest_version).to eq 'here i am'
        end

        it 'does not include other modules in the namespace' do
          expect(subject.new).to_not respond_to(:from_class_mod)
          subject.usable mod
          expect(subject.new).to_not respond_to(:from_class_mod)
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

    context 'when a UsableSpec is defined' do
      before { mod.const_set :UsableSpec, class_mod }
      after { mod.send :remove_const, :UsableSpec }

      it 'adds the methods from the UsableSpec' do
        subject.usable mod
        expect(subject.usables.available_methods.keys.sort).to eq [:destroy_version, :from_class_mod, :latest_version, :versions]
        expect(subject.usables.available_methods).to include(:from_class_mod)
      end
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

      context 'when the test module has defined a constant named "UsableSpec"' do
        before { mod.const_set :UsableSpec, spec_mod }
        after { mod.send :remove_const, :UsableSpec }

        it 'uses just "UsableSpec" as the name of the included Spec mod' do
          expect {
            Subject.usable mod
          }.to change { ancestors }.to include 'Subject::UsableSpecUsed'
          assert_index_of_mod 'Subject::UsableSpecUsed', 2
        end
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

      context 'when the module has a "UsableSpec" defined' do
        before { TestMod.const_set :UsableSpec, spec_mod }
        after { TestMod.send :remove_const, :UsableSpec }

        context 'when there are methods to remove via the :only option' do
          it 'appends "UsableSpec" to the name of the modified module' do
            expect {
              Subject.usable TestMod, only: :update_version
            }.to change { ancestors }.to include 'Subject::TestModUsableSpecUsed'
            assert_index_of_mod 'Subject::TestModUsableSpecUsed', 2
          end

          it 'does not mutate the original UsableSpec module' do
            expect {
              Subject.usable TestMod, only: :destroy_version
            }.to_not change { TestMod::UsableSpec.instance_methods(false) }
          end
        end

        context 'when given the :only option is empty' do
          it 'uses the module name without defining a new constant under Subject' do
            expect {
              Subject.usable TestMod
            }.to change { ancestors }.to include 'TestMod::UsableSpec'
            assert_index_of_mod 'TestMod::UsableSpec', 2
          end
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
end
