require "spec_helper"

describe Usable do
  subject { Class.new { extend ::Usable } }

  let(:mod) do
    Module.new do
      def versions
        "Saving #{self.class.usable_config.max_versions} versions to #{self.class.usable_config.table_name} table"
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

  after(:each) { subject.usable_config = nil }

  describe "#usable_config" do
    it "assigns @usable_config" do
      expect(subject.usable_config).to be_a Usable::Config
    end
  end

  describe "#usable" do
    context "unless (self < mod)" do
      it "calls :send with :include and -mod-" do
        expect(subject).to receive(:include).with(instance_of(Module))
        subject.usable mod
      end
    end

    it "assign the given :options as values to @usable_config" do
      expect {
        subject.usable mod, table_name: 'custom', max_versions: 50
      }.to change(subject.usable_config, :to_h).from({}).to(table_name: 'custom', max_versions: 50)
    end


    context "when block_given?" do
      it "yields @usable_config to the given block" do
        expect {
          subject.usable mod do |usable_config|
            usable_config.max_versions = 10
          end
        }.to change(subject.usable_config, :max_versions).from(nil).to(10)
      end

      it "uses the usable_config in the method calls" do
        subject.usable mod, table_name: 'versions' do |usable_config|
          usable_config.max_versions = 10
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

    context 'when the given module has defined a +usable_config+' do
      before do
        mod.extend described_class
        mod.usable_config[:key] = 'secret'
      end

      it 'copies the usable config settings over to the subject' do
        expect { subject.usable mod }.to change { subject.usable_config[:key] }.from(nil).to('secret')
      end

      context "when the subject is given settings with the same name as the module's setting" do
        it 'uses the given settings' do
          expect { subject.usable mod, key: 'public' }.to change { subject.usable_config[:key] }.from(nil).to('public')
        end
      end
    end
  end

  describe '#available_methods' do
    it 'returns the list of unbound methods we defined on the target' do
      expect(subject.usable_config.available_methods).to be_empty
      subject.usable mod
      expect(subject.usable_config.available_methods.keys.sort).to eq [:destroy_version, :latest_version, :versions]
      expect(subject.usable_config.available_methods[:destroy_version]).to be_kind_of UnboundMethod
    end

    context 'when a UsableSpec is defined' do
      before { mod.const_set :UsableSpec, class_mod }
      after { mod.send :remove_const, :UsableSpec }

      it 'adds the methods from the UsableSpec' do
        subject.usable mod
        expect(subject.usable_config.available_methods.keys.sort).to eq [:destroy_version, :from_class_mod, :latest_version, :versions]
        expect(subject.usable_config.available_methods).to include(:from_class_mod)
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

end
