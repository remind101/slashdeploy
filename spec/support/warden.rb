class MockWarden
  attr_reader :user

  def authenticated?
    @user.present?
  end

  def set_user(user, *_args)
    @user = user
  end

  def logout
    @user = nil
  end
end
