require 'spec_helper'
require 'active_record/connection_adapters/postgresql_adapter'

describe 'Type Casting' do
  describe 'String / Text' do
    context 'ActiveRecord::Type::String' do
      let(:type) { ActiveRecord::Type::String.new }

      it { expect(Panko::_type_cast(type, true)).to          eq('t') }
      it { expect(Panko::_type_cast(type, false)).to         eq('f') }
      it { expect(Panko::_type_cast(type, 123)).to           eq('123') }
      it { expect(Panko::_type_cast(type, 'hello world')).to eq('hello world') }
    end

    context 'ActiveRecord::Type::Text' do
      let(:type) { ActiveRecord::Type::Text.new }

      it { expect(Panko::_type_cast(type, true)).to          eq('t') }
      it { expect(Panko::_type_cast(type, false)).to         eq('f') }
      it { expect(Panko::_type_cast(type, 123)).to           eq('123') }
      it { expect(Panko::_type_cast(type, 'hello world')).to eq('hello world') }
    end

    # We treat uuid as stirng, there is no need for type cast before serialization
    context 'ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid' do
      let(:type) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid.new }

      it { expect(Panko::_type_cast(type, 'e67d284b-87b8-445e-a20d-3c76ea353866')).to eq('e67d284b-87b8-445e-a20d-3c76ea353866') }
    end
  end

  describe 'Integer' do
    context 'ActiveRecord::Type::Integer' do
      let(:type) { ActiveRecord::Type::Integer.new }

      it { expect(Panko::_type_cast(type, '')).to  be_nil }
      it { expect(Panko::_type_cast(type, nil)).to  be_nil }

      it { expect(Panko::_type_cast(type, 1)).to  eq(1) }
      it { expect(Panko::_type_cast(type, '1')).to  eq(1) }
      it { expect(Panko::_type_cast(type, 1.7)).to  eq(1) }

      it { expect(Panko::_type_cast(type, true)).to  eq(1) }
      it { expect(Panko::_type_cast(type, false)).to  eq(0) }

      it { expect(Panko::_type_cast(type, [6])).to  be_nil }
      it { expect(Panko::_type_cast(type, six: 6)).to  be_nil }
    end

    context 'ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer' do
      let(:type) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer.new }

      it { expect(Panko::_type_cast(type, '')).to  be_nil }
      it { expect(Panko::_type_cast(type, nil)).to  be_nil }

      it { expect(Panko::_type_cast(type, 1)).to  eq(1) }
      it { expect(Panko::_type_cast(type, '1')).to  eq(1) }
      it { expect(Panko::_type_cast(type, 1.7)).to  eq(1) }

      it { expect(Panko::_type_cast(type, true)).to  eq(1) }
      it { expect(Panko::_type_cast(type, false)).to  eq(0) }

      it { expect(Panko::_type_cast(type, [6])).to  be_nil }
      it { expect(Panko::_type_cast(type, six: 6)).to  be_nil }
    end
  end

  context 'ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Json' do
    let(:type) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Json.new }

    it { expect(Panko::_type_cast(type, '')).to  be_nil }
    it { expect(Panko::_type_cast(type, 'shnitzel')).to be_nil }
    it { expect(Panko::_type_cast(type, nil)).to  be_nil }

    it { expect(Panko::_type_cast(type, '{"a":1}')).to  eq({ 'a' => 1 }) }
    it { expect(Panko::_type_cast(type, '[6,12]')).to  eq([6, 12]) }

    it { expect(Panko::_type_cast(type, { "a" => 1 })).to  eq({ 'a' => 1 }) }
    it { expect(Panko::_type_cast(type, [6,12])).to  eq([6, 12]) }
  end

  context 'ActiveRecord::Type::Boolean' do
    let(:type) { ActiveRecord::Type::Boolean.new }

    it { expect(Panko::_type_cast(type, '')).to be_nil }
    it { expect(Panko::_type_cast(type, nil)).to be_nil }

    it { expect(Panko::_type_cast(type, true)).to be_truthy }
    it { expect(Panko::_type_cast(type, '1')).to be_truthy }
    it { expect(Panko::_type_cast(type, 't')).to be_truthy }
    it { expect(Panko::_type_cast(type, 'T')).to be_truthy }
    it { expect(Panko::_type_cast(type, 'true')).to be_truthy }
    it { expect(Panko::_type_cast(type, 'TRUE')).to be_truthy }

    it { expect(Panko::_type_cast(type, false)).to be_falsey }
    it { expect(Panko::_type_cast(type, '0')).to be_falsey }
    it { expect(Panko::_type_cast(type, 'f')).to be_falsey }
    it { expect(Panko::_type_cast(type, 'F')).to be_falsey }
    it { expect(Panko::_type_cast(type, 'false')).to be_falsey }
    it { expect(Panko::_type_cast(type, 'FALSE')).to be_falsey }
  end

end
