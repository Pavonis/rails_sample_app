# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe User do
	
	before do
		@user = User.new(	name: "Example User",
							email: "example@mail.com",
							password: "foobar",
							password_confirmation: "foobar")
	end
	
	subject{ @user }
	
	it { should respond_to(:name) }
	it { should respond_to(:email) }
	it { should respond_to(:password_digest) }
	it { should respond_to(:password) }
	it { should respond_to(:password_confirmation) }
	it { should respond_to(:remember_token) }
	it { should respond_to(:authenticate) }
	it { should respond_to(:admin) }
	
	it { should respond_to(:feed) }
	it { should respond_to(:relationships) }
	it { should respond_to(:followed_users) }
	it { should respond_to(:reverse_relationships) }
	it { should respond_to(:followers) }
	it { should respond_to(:following?) }
	it { should respond_to(:follow!) }
	it { should respond_to(:unfollow!) }
	
	it { should respond_to(:microposts) }
	
	it { should be_valid }
	it { should_not be_admin }
	
	describe "when admin is set to 'true'" do
		
		before { @user.toggle!(:admin) }
		it { should be_admin }
	end
	
	describe "When no name is present" do
		before { @user.name = " " }
		it { should_not be_valid }
	end
	
	describe "When name is too long" do
		before { @user.name = "a" * 51 }
		it { should_not be_valid }
	end
	
	describe "when no password is present" do
		before { @user.password = @user.password_confirmation = " " }
		it { should_not be_valid }
	end
	
	describe "when pasword and confirmation does not match" do
		before { @user.password_confirmation = "mismatch" }
		it { should_not be_valid }
	end
	
	describe "when no password confirmation is entered" do
		before { @user.password_confirmation = "" }
		it { should_not be_valid }
	end
	
	describe "with a password that is too short" do
		before { @user.password = @user.password_confirmation = "a" * 5 }
		it { should_not be_valid }
	end
	
	describe "remember token" do
		before { @user.save }
		its(:remember_token) { should_not be_blank }
	end
	
	describe "return value of authentication method" do
		
		before { @user.save }
		let(:found_user) { User.find_by_email(@user.email) }
		
		describe "with valid password" do
			it { should == found_user.authenticate(@user.password) }
		end
		
		describe "with invalid password" do
			let(:user_for_invalid_password) { found_user.authenticate("invalid") }
			
			it { should_not == user_for_invalid_password }
			specify { user_for_invalid_password.should be_false }
		end
	end
	
	describe "when no email is present" do
		before { @user.email = " " }
		it { should_not be_valid }
	end
	
	describe "when email format is invalid" do
		it "should be invalid" do
			addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
			addresses.each do |invalid_address|
				@user.email = invalid_address
				@user.should_not be_valid
			end
		end
	end
	
	describe "when email format is valid" do
		it "should be valid" do
			addresses = %w[user@foo.com A_User@f.b.org frst.lst@foo.jp a+b@foo.cn]
			addresses.each do |valid_address|
				@user.email = valid_address
				@user.should be_valid
			end
		end
	end
	
	describe "when email is already taken" do
		before do
			user_with_same_email = @user.dup
			user_with_same_email.email = @user.email.upcase
			user_with_same_email.save
		end
		
		it { should_not be_valid }
	end
	
	# micropost associations
	
	
	describe "microposts associations" do
		
		before { @user.save }
		let!(:older_micropost) do
			FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)
		end
		let!(:newer_micropost) do
			FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago)
		end
		
		it "should have microposts in the right order" do
			@user.microposts.should == [newer_micropost, older_micropost]
		end
		
		it "should destroy associated microposts" do
			microposts = @user.microposts.dup
			@user.destroy
			microposts.should_not be_empty
			microposts.each do | micropost |
				Micropost.find_by_id(micropost.id).should be_nil
			end
		end
		
		describe "status" do
			let(:unfollowed_post) do
				FactoryGirl.create(:micropost, user: FactoryGirl.create(:user))
			end
			let(:followed_user) { FactoryGirl.create(:user) }
			
			before do
				@user.follow!(followed_user)
        		3.times { followed_user.microposts.create!(content: "Lorem ipsum") }
			end
			
			its(:feed) { should include(newer_micropost) }
      		its(:feed) { should include(older_micropost) }
      		its(:feed) { should_not include(unfollowed_post) }
      		its(:feed) do
      			followed_user.microposts.each do |micropost|
      				should include(micropost)
      			end
      		end
		end
	end
	
	describe "following" do
		let(:other_user) { FactoryGirl.create(:user) }
		before do
			@user.save
			@user.follow!(other_user)
		end
		
		it { should be_following(other_user) }
		its(:followed_users) { should include(other_user) }
		
		describe "followed users" do
			subject { other_user }
			its(:followers) { should include(@user) }
		end
		
		describe "and unfollowing" do
			before { @user.unfollow!(other_user) }
			its(:followed_users) { should_not include(other_user) }
		end
	end
end
