require 'spec_helper'
require 'roust'

describe Roust do
  include_context 'credentials'

  describe 'authentication' do
    it 'authenticates on instantiation' do
      rt = Roust.new(credentials)
      rt.authenticated?.should be_true
    end
  end
end
