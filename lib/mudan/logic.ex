defmodule Mudan.Logic do
  def user(user_id) do
    profile = Mudan.Utils.get_user_profile(user_id)
  end
end
