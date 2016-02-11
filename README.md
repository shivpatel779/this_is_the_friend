There are several articles about how to do a friendship model for rails. Many of them are focussed on the twitter style following model, and some use gems, but I really wanted a straightforward Facebook Style Model. One where you request a friend and they accept the request.

The following will walk through the quickest way I’ve discovered so far.

Quick aside, the fabulous [socialization](https://github.com/cmer/socialization) gem does this for you, but it’s nice to understand a little of what’s going on under the hood sometimes right?

First up, a few assumptions
* you’ve got a rails app or know enough to create one
* you have a User model either home grown or (as in my case) [devise gem](https://github.com/plataformatec/devise)
* you have a current_user method to find the current user (devise provides one by default)

Ok, lets begin

I’m going to skip using rails amazing scaffolds, they are a little too verbose for the simplicity of this, but feel free to use them if you want:

```terminal
$rails generate model Friendship user_id:integer friend_id:integer accepted:boolean
```
There’s one thing I want to do for this migration, add default: false to the boolean. I have a mild suspicion this is default behavior, but I add it to save having to send false with each new request.
Here is the updated migration with the added default behavior:

```ruby

class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.integer :user_id
      t.integer :friend_id
      t.boolean :accepted, default: false

      t.timestamps null: false
    end
  end
end

```
run rake db:migrate and lets work on associating the 2 models, User and Friendship!

So, the User has_many friendships and the Friendships belongs_to the user. But the issue is that we want to reference them singularly as one. At the moment the Friendship Model has a user_id and a friend_id. Rails will automatically work out the user_id portion, but we need to tell it how the friend_id portion works. (see the aforementioned rails cast for a better explanation)

This is the Friendship model:

```ruby
#app/models.friendship.rb

class Friendship < ActiveRecord::Base
	belongs_to :user
	belongs_to :friend, class_name: "User"
end

```
And here is the User model (minus the devise stuff which you should leave in there please :) )

```ruby
# app/models/user.rb

	has_many :friendships
	has_many :received_friendships, class_name: "Friendship", foreign_key: "friend_id"

	has_many :active_friends, -> { where(friendships: { accepted: true}) }, through: :friendships, source: :friend
	has_many :received_friends, -> { where(friendships: { accepted: true}) }, through: :received_friendships, source: :user
	has_many :pending_friends, -> { where(friendships: { accepted: false}) }, through: :friendships, source: :friend
	has_many :requested_friendships, -> { where(friendships: { accepted: false}) }, through: :received_friendships, source: :user

	def friends
	  active_friends | received_friends
	end

```

See where we told Rails that we have the friend_id as a foreign key? That’s us giving rails a gentle nudge to work out the two users who are in the friendship. That friends method at the end is a succinct way to call the method in the app and bring back friends.

So, we need a controller to work it’s magic with this amazing model, then we need view/’s

Time to generate a controller (unless you scaffolded this).
We only need a create action, an update action, and a destroy action here, so we generate that like this:

```terminal
$rails generate controller Friendships create update destroy
```

Now I’m going to clean up the routes.rb file to make it a little cleaner by adding the following and removing the routes that rails created when we generated the controller. (you definitely want to leave anything else that’s in there, from devise and your other controllers etc, else stuff will break)

```ruby
# config/routes.rb
resources :friendships, only: [:create, :update, :destroy]

```

Now for the controller itself. We need a way to find the friendship (@friendship) and create or update depending on our needs. In this case we'll use the create method for requesting a friendship, the update method to accept a friendship, and the destroy method to decline the friendship.

```ruby
# app/controllers/friendships_controller.rb

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

```

Finally the views. You'll have a specific view in mind, so this is a very general view. Points to note, the way we post our requests, the layouts excluding current_user etc, and the list of requested. All of these may be handy for you.

```erb
# app/views/whatever.html.erb

# Here is a way to add an add friend link to a list of users.
# I'd recommend adding an unless or if statement to filter current_user and already requested friends.

<ul>
	<% @users.each do |user| %>
		<li>
			<%= user.name %> |
			<%= link_to "Add Friend", friendships_path(friend_id: user), method: :post %>
		</li>
	<% end %>
</ul>

# Here is a list of your pending requests

<ul>
    <% current_user.requested_friendships.each do |request| %>
    <li>
      <%= request.name %>
      <%= link_to "Accept",  friendship_path(id: request.id), method: "put" %>
      <%= link_to "Decline", friendship_path(id: request.id), method: :delete %>
    </li>
  <% end %>
</ul>

```
The above views could obviously use styling and better presentation, but the link_to are the main part to understand.


Hope this helps clarify some things and makes it easy to put together.

It would be remiss of me not to mention the following sources for this:
* [railscasts](http://railscasts.com/episodes/163-self-referential-association)
* [this stackoverflow](http://stackoverflow.com/questions/25101089/mutual-friendship-rails-4/25105635#25105635)
* [rails tutorial](https://www.railstutorial.org)


My blog [tobyh.com](http://tobyh.com)
