require 'spec_helper'

RSpec.describe 'Interval', type: :feature do
  let(:connection) { ActiveRecord::Base.connection }

  context 'on settings' do
    it 'must be set to ISO 8601' do
      expect(connection.select_value('SHOW IntervalStyle')).to eql('iso_8601')
    end
  end

  context 'on table definition' do
    subject { ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.new('articles') }

    it 'has the interval method' do
      expect(subject).to respond_to(:interval)
    end

    it 'can define an interval column' do
      subject.interval('duration')
      expect(subject['duration'].name).to eql('duration')
      expect(subject['duration'].type).to eql(:interval)
    end
  end

  context 'on schema' do
    it 'can be used on tables too' do
      dump_io = StringIO.new
      ActiveRecord::SchemaDumper.dump(connection, dump_io)
      expect(dump_io.string).to match /t\.interval +"duration"/
    end
  end

  context 'on OID' do
    let(:reference) { 1.year + 2.months + 3.days + 4.hours + 5.minutes + 6.seconds }
    subject { Torque::PostgreSQL::Adapter::OID::Interval.new }

    context 'on deserialize' do
      it 'returns nil' do
        expect(subject.deserialize(nil)).to be_nil
      end

      it 'returns duration' do
        value = subject.deserialize('P1Y2M3DT4H5M6S')

        expect(value).to be_a(ActiveSupport::Duration)
        expect(value).to eq(reference)
      end
    end

    context 'on serialize' do
      it 'returns nil' do
        expect(subject.serialize(nil)).to be_nil
      end

      it 'returns seconds as string' do
        expect(subject.serialize(3600.seconds)).to eq('PT3600S')
      end

      it 'retruns sample as string' do
        expect(subject.serialize(reference)).to eq('P1Y2M3DT4H5M6S')
      end
    end

    context 'on cast' do
      it 'accepts nil' do
        expect(subject.cast(nil)).to be_nil
      end

      it 'accepts string' do
        value = subject.cast('P1Y2M3DT4H5M6S')
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value).to eq(reference)
      end

      it 'accepts duration' do
        value = subject.cast(5.days)
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value).to eql(value)
      end

      it 'accepts small seconds numeric' do
        value = subject.cast(30)
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value).to eq(30)
      end

      it 'accepts long seconds numeric' do
        value = subject.cast(reference.to_i)
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value).to eq(reference)
      end

      it 'accepts array with Y-M-D H:M:S format' do
        value = subject.cast([1, 2, 3, 4, 5, 6])
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value).to eq(reference)
      end

      it 'accepts array with empty values' do
        value = subject.cast([nil, 0, 12, 30, 0])
        sample = 12.hours + 30.minutes
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value.inspect).to eq(sample.inspect)
        expect(value).to eq(sample)
      end

      it 'accepts array with string' do
        value = subject.cast(['45', '15'])
        sample = 45.minutes + 15.seconds
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value.inspect).to eq(sample.inspect)
        expect(value).to eq(sample)
      end

      it 'accepts hash' do
        value = subject.cast({years: 1, months: 2, days: 3, hours: 4, minutes: 5, seconds: 6})
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value).to eq(reference)
      end

      it 'accepts hash with extra elements' do
        value = subject.cast({extra: 1, hours: 12, minutes: 30})
        sample = 12.hours + 30.minutes
        expect(value).to be_a(ActiveSupport::Duration)
        expect(value).to eq(sample)
      end

      it 'returns any other type of value as it is' do
        value = subject.cast(true)
        expect(value).to eql(true)
      end
    end
  end
end
