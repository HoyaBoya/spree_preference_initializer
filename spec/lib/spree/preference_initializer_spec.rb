require 'spec_helper'
require 'rake'
require 'spree_preference_initializer/spree/preference_initializer'

describe Spree::PreferenceInitializer do
  before(:each) do
    Spree::PreferenceInitializer.reset!
  end

  describe 'load_config_property' do
    context 'when asking for foo' do
      it 'should return bar' do
        Spree::PreferenceInitializer.load_config_property('spree_backend_configuration', 'foo', File.dirname(__FILE__) + "/config.yml").should == 'bar'
      end
    end  
  end

  describe 'load_gateways' do
    context 'when given gateways.yml' do
      subject { Spree::PreferenceInitializer.load_gateways(File.dirname(__FILE__) + "/gateways.yml") }

      before(:each) do
        Spree::Gateway.delete_all
        Spree::Gateway::BraintreeGateway.create!(name: 'Braintree Credit Card')
        Spree::Gateway.first.id.should == 1
        Spree::Gateway.count.should == 1
      end

      [:merchant_id, :merchant_account_id, :public_key, :private_key, :client_side_encryption_key, :environment].each do |i|
        it "should initialize a Spree::Gateway::BraintreeGateway with #{i}" do
          subject
          Spree::Gateway::BraintreeGateway.find(1).options[i].should_not be_nil
        end
      end
    end

    context 'when given gateways_by_name.yml' do
      subject { Spree::PreferenceInitializer.load_gateways(File.dirname(__FILE__) + "/gateways_by_name.yml") }

      before(:each) do
        Spree::Gateway.delete_all
        Spree::Gateway::BraintreeGateway.create!(name: 'Test Credit Card')
        Spree::Gateway.count.should == 1
      end

      [:merchant_id, :merchant_account_id, :public_key, :private_key, :client_side_encryption_key, :environment].each do |i|
        it "should initialize a Spree::Gateway::BraintreeGateway with #{i}" do
          subject
          Spree::Gateway::BraintreeGateway.find(1).options[i].should_not be_nil
        end
      end
    end

    context 'when a non DB error is raised' do
      subject { Spree::PreferenceInitializer.load_gateways(File.dirname(__FILE__) + "/malformed_config.yml") }

      it 'should not catch error' do
        lambda {
          subject
        }.should raise_error
      end
    end

##
# Dicey test to simulate the 0 migration issue when using the preference initialzier.
#
# They are commented out to avoid annoying everyone with extra long tests just to validate this scenario.
#
=begin
    context 'when the DB does not exist' do
      before(:all) do
        Rails.env = ENV['RAILS_ENV'] = 'test'
        @rake = Rake::Application.new
        Rake.application = @rake
        @rake.init
        @rake.load_rakefile
        @rake['db:drop'].invoke
        @rake['db:create'].invoke
      end 

      subject { Spree::PreferenceInitializer.load_gateways }

      it 'should not explode' do
        subject
      end

      it 'should have warnings' do
        subject
        Spree::PreferenceInitializer.warnings.size.should == 1
      end
      
      it 'should notify Honeybadger' do
        Honeybadger.should_receive(:notify) 
        subject
      end

      after(:all) do
        @rake['db:migrate'].invoke
      end
    end
=end

  end

  describe 'load_config' do
    context 'when config is malformed' do
      subject { Spree::PreferenceInitializer.load_configs(File.dirname(__FILE__) + "/malformed_config.yml") }    

      it 'should raise an error' do
        lambda {
          subject
        }.should raise_error
      end
    end

    context 'when config class is missing property' do
      subject { Spree::PreferenceInitializer.load_configs(File.dirname(__FILE__) + "/bad_config.yml") }

      it 'should not raise an error' do
        lambda {
          subject
        }.should_not raise_error
      end
    end

    context 'when config class is not valid' do
      subject { Spree::PreferenceInitializer.load_configs(File.dirname(__FILE__) + "/another_bad_config.yml") } 

      it 'should not raise an error' do
        lambda {
          subject
        }.should raise_error
      end 
    end

    context 'when configuration class contains foo' do
      subject { Spree::PreferenceInitializer.load_configs(File.dirname(__FILE__) + "/config.yml") }

      it 'should set foo' do
        subject
        Spree::GoodConfiguration.new.foo.should == 'bar' 
      end
    end
  end

  protected

  class Spree::GoodConfiguration < Spree::Preferences::Configuration
    preference :foo,      :string
  end

  class Spree::BadConfiguration < Spree::Preferences::Configuration
  end

  class Spree::AnotherBadConfiguration < Spree::Preferences::Configuration
    include ActiveModel::Validations

    preference :something, :string

    validates :something, presence: true
  end
end
