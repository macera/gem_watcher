module DisplayVersionHelper
  shared_examples 'display_version' do
    let(:obj_name) { described_class.to_s.underscore.to_sym }
    let(:model) { create(obj_name) }

    describe '#split_version' do
      context 'マイナー、パッチバージョン両方ある場合(パッチ以降に.が付いている)' do
        subject { model.split_version('1.2.3.4') }
        it { is_expected.to eq ['1', '2', '3.4'] }
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
end