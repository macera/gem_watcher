module VersionSettingHelper
  shared_examples 'display_version' do
    let(:obj_name) { described_class.to_s.underscore.to_sym }
    let(:model) { create(obj_name) }

    describe '#split_version' do
      context 'マイナー、パッチ、リビジョンがある場合(リビジョン以降に.が付いている)' do
        subject { model.split_version('1.2.3.4.5') }
        it { is_expected.to eq ['1', '2', '3', '4.5'] }
      end
      context 'マイナー、パッチ、リビジョンがある場合' do
        subject { model.split_version('1.2.3.4') }
        it { is_expected.to eq ['1', '2', '3', '4'] }
      end
      context 'マイナー、パッチバージョン両方ある場合' do
        subject { model.split_version('1.2.3') }
        it { is_expected.to eq ['1', '2', '3'] }
      end
      context 'マイナーバージョンがある場合' do
        subject { model.split_version('1.2') }
        it { is_expected.to eq ['1', '2'] }
      end
      context 'マイナーバージョンがない場合' do
        subject { model.split_version('1') }
        it { is_expected.to eq ['1'] }
      end
    end
  end

  shared_examples 'versioning' do
    let(:obj_name) { described_class.to_s.underscore.to_sym }
    let(:model) { create(obj_name) }

    describe '.skip_alphabetic_version_to_next' do
      context 'パッチがnilの場合' do
        subject { model.skip_alphabetic_version_to_next(['4','2']) }
        it { is_expected.to eq ['4','2'] }
      end
      context 'パッチが数値の場合' do
        subject { model.skip_alphabetic_version_to_next(['4','2','1']) }
        it { is_expected.to eq ['4','2','1'] }
      end
      context 'パッチに英字を含む場合' do
        subject { model.skip_alphabetic_version_to_next(['4','2','a1']) }
        it { is_expected.to eq ['4','2','', 'a1'] }
      end
    end
  end

end