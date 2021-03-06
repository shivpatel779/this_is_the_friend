class FriendshipsController < ApplicationController

	def create
	  @friendship = current_user.friendships.build(friend_id: params[:friend_id])
	  if @friendship.save
	    flash[:notice] = "Friend requested."
	    redirect_to :back
	  else
	    flash[:error] = "Unable to request friendship."
	    redirect_to :back
	  end
	end

	def update
	@friendship = Friendship.find_by(id: params[:id])
	@friendship.update(status: "accepted")
	  if @friendship.save
	    redirect_to root_url, notice: "Successfully confirmed friend!"
	  else
	    redirect_to root_url, notice: "Sorry! Could not confirm friend!"
	  end
	end

	def destroy
	  @friendship = Friendship.find_by(id: params[:id])
	  @friendship.destroy
	  flash[:notice] = "Removed friendship."
	  redirect_to :back
	end

end
