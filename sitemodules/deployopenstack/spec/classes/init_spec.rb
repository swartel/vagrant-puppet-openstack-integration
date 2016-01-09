require 'spec_helper'
describe 'deployopenstack' do

  context 'with defaults for all parameters' do
    it { should contain_class('deployopenstack') }
  end
end
