# frozen_string_literal: true

require "spec_helper"
require "active_record/connection_adapters/postgresql_adapter"

describe "Type Casting" do
  describe "String / Text" do
    context "ActiveRecord::Type::String" do
      let(:type) { ActiveRecord::Type::String.new }

      it { expect(Panko._type_cast(type, true)).to          eq("t") }
      it { expect(Panko._type_cast(type, nil)).to           be_nil }
      it { expect(Panko._type_cast(type, false)).to         eq("f") }
      it { expect(Panko._type_cast(type, 123)).to           eq("123") }
      it { expect(Panko._type_cast(type, "hello world")).to eq("hello world") }
    end

    context "ActiveRecord::Type::Text" do
      let(:type) { ActiveRecord::Type::Text.new }

      it { expect(Panko._type_cast(type, true)).to          eq("t") }
      it { expect(Panko._type_cast(type, false)).to         eq("f") }
      it { expect(Panko._type_cast(type, 123)).to           eq("123") }
      it { expect(Panko._type_cast(type, "hello world")).to eq("hello world") }
    end

    # We treat uuid as stirng, there is no need for type cast before serialization
    context "ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid" do
      let(:type) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid.new }

      it { expect(Panko._type_cast(type, "e67d284b-87b8-445e-a20d-3c76ea353866")).to eq("e67d284b-87b8-445e-a20d-3c76ea353866") }
    end
  end

  describe "Integer" do
    context "ActiveRecord::Type::Integer" do
      let(:type) { ActiveRecord::Type::Integer.new }

      it { expect(Panko._type_cast(type, "")).to  be_nil }
      it { expect(Panko._type_cast(type, nil)).to be_nil }

      it { expect(Panko._type_cast(type, 1)).to eq(1) }
      it { expect(Panko._type_cast(type, "1")).to  eq(1) }
      it { expect(Panko._type_cast(type, 1.7)).to  eq(1) }

      it { expect(Panko._type_cast(type, true)).to eq(1) }
      it { expect(Panko._type_cast(type, false)).to eq(0) }

      it { expect(Panko._type_cast(type, [6])).to be_nil }
      it { expect(Panko._type_cast(type, six: 6)).to be_nil }
    end

    context "ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer", if: ENV["RAILS_VERSION"].start_with?("4.2") do
      let(:type) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Integer.new }

      it { expect(Panko._type_cast(type, "")).to be_nil }
      it { expect(Panko._type_cast(type, nil)).to be_nil }

      it { expect(Panko._type_cast(type, 1)).to eq(1) }
      it { expect(Panko._type_cast(type, "1")).to  eq(1) }
      it { expect(Panko._type_cast(type, 1.7)).to  eq(1) }

      it { expect(Panko._type_cast(type, true)).to eq(1) }
      it { expect(Panko._type_cast(type, false)).to eq(0) }

      it { expect(Panko._type_cast(type, [6])).to be_nil }
      it { expect(Panko._type_cast(type, six: 6)).to be_nil }
    end
  end

  context "ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Json" do
    let(:type) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Json.new }

    it { expect(Panko._type_cast(type, "")).to be_nil }
    it { expect(Panko._type_cast(type, "shnitzel")).to be_nil }
    it { expect(Panko._type_cast(type, nil)).to be_nil }

    it { expect(Panko._type_cast(type, '{"a":1}')).to eq("a" => 1) }
    it { expect(Panko._type_cast(type, "[6,12]")).to eq([6, 12]) }

    it { expect(Panko._type_cast(type, "a" => 1)).to eq("a" => 1) }
    it { expect(Panko._type_cast(type, [6, 12])).to eq([6, 12]) }
  end

  context "ActiveRecord::Type::Boolean" do
    let(:type) { ActiveRecord::Type::Boolean.new }

    it { expect(Panko._type_cast(type, "")).to be_nil }
    it { expect(Panko._type_cast(type, nil)).to be_nil }

    it { expect(Panko._type_cast(type, true)).to be_truthy }
    it { expect(Panko._type_cast(type, "1")).to be_truthy }
    it { expect(Panko._type_cast(type, "t")).to be_truthy }
    it { expect(Panko._type_cast(type, "T")).to be_truthy }
    it { expect(Panko._type_cast(type, "true")).to be_truthy }
    it { expect(Panko._type_cast(type, "TRUE")).to be_truthy }

    it { expect(Panko._type_cast(type, false)).to be_falsey }
    it { expect(Panko._type_cast(type, "0")).to be_falsey }
    it { expect(Panko._type_cast(type, "f")).to be_falsey }
    it { expect(Panko._type_cast(type, "F")).to be_falsey }
    it { expect(Panko._type_cast(type, "false")).to be_falsey }
    it { expect(Panko._type_cast(type, "FALSE")).to be_falsey }
  end

  context "Time" do
    let(:type) { ActiveRecord::Type::DateTime.new }
    let(:date) { DateTime.new(2017, 3, 4, 12, 45, 23) }
    let(:utc) { ActiveSupport::TimeZone.new("UTC") }

    it "returns ISO8601 strings" do
      expect(Panko._type_cast(type, date.in_time_zone(utc).iso8601)).to eq("2017-03-04T12:45:23Z")
    end

    it "converts string from datbase to utc time zone" do
      time = "2017-07-10 09:26:40.937392"
      result = DateTime.new(2017, 7, 10, 9, 26, 40, 937_392).in_time_zone(utc)

      expect(Panko._type_cast(type, time)).to eq(result.iso8601)
    end
  end
end
