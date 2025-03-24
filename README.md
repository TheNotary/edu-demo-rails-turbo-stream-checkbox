# Rails - Trubo Stream Checkboxes

Have you ever wanted a control in your app to immediately update the backend without the user needing to bother with clicking a submit button?  This repository intends to demonstrate the creation of a database-backed checkbox that toggles an entry in the database immediately after the user clicks the checkbox.  The user's frontend should also react to this change in state once the backend has completed it's update operation successfully.

**Turbo** is a neat technology incorporated into the vanilla Rails stack to enable the rapid development of single page applications that feel alive and responsive. The idea is to use AJAX/ websockets to transmit partial updates to the browser.  There are lots of frameworks out there that can do this, but rails is the only one I'm aware of that defines these reactive application behaviors via markup language rather than attempting to define the behavior using relatively more complex and less expressive procedural logic.

## Step 1: Supply the Prompts Needed to Generator the Base App

```bash
# Generate the App
rails new edu-demo-rails-turbo-streams-checkbox
cd edu-demo-rails-turbo-streams-checkbox
alias r="bin/rails"

# Setup the database and scaffold out the views
r g scaffold Posts title:string body:text published:boolean
r db:migrate

# This just uncomments the last line in config/routes.rb
sed -i 's/# \(root "posts#index"\)/\1/' config/routes.rb

r s
```

## Step 2: Add the Checkbox to _post partial

Before you do anything, browse to the app and make a couple post's with the UI just for fun.  

Once you have some seed data and can see the app working, modify the `_post` partial to include a form dedicated just to the checkbox.  

(app/views/posts/_post.html.erb)
```html
<div id="<%= dom_id post %>">
  <p>
    <strong>Title:</strong>
    <%= post.title %>
  </p>

  <p>
    <strong>Body:</strong>
    <%= post.body %>
  </p>

  <%= form_with(model: post) do |form| %>
    <p>
      <%= form.label    :published %>
      <%= form.checkbox :published %>
    </p>
    <%= form.submit class: "submit" %>
  <% end %>

</div>
```

I'm more or less keeping the original scaffolding, but wrapping the published checkbox in a form_with helper.  This gives us a form for every post with a checkbox... along with a hideous submit button.  It's functional, but in our next step we make it functional and nice.


## Step 3: Add the Data Frame

I'm adding a `<data-frame>` although strictly speaking, this **should** be written as a div.  I was going to do some fancy WebSocket stuff for the form submission but decided I didn't have a strong enough use-case in a SaaS product I've been working on.  

Also, I'm adding a class to the turbo-frame which allows me to write some css styling to disable the checkbox when the user clicks it and begins a patch request.  

(app/views/posts/_post.html.erb)
```html
.
.
.
<turbo-frame id="#{dom_id(post)}_published" class="published">
  <%= form_with(model: post, url: update_checked_post_path(post) ) do |form| %>
    <p>
      <%= form.label    :published, for: "#{dom_id(post)}_published" %>
      <%= form.checkbox :published,  id: "#{dom_id(post)}_published", onchange: "this.form.requestSubmit()"  %>
    </p>
  <% end %>
</turbo-frame>
.
.
.
```

The styling here might feel a bit cheeky, and in some situations may need to be reworked to involve specific color changes, but in this demo it works just as setting the disabled attribute in javascript, plus allows us to not invest any time writing javascript.  If that bums you out, well, roll this out in React Redux and you'll appreciate the approach much more.  

(app/assets/stylesheets/autosaving_checkbox.css)
```css
turbo-frame.published form[aria-busy="true"] {
  input[type="checkbox"],
  label {
    pointer-events: none; /* disable the inputs */
    opacity: 0.5;         /* make the inputs look disabled */
  }
}
```

Oh, you spotted javascript after all?  Yes it's there, the `form.checkbox` helper attaches an `onchange` handler that invokes `this.form.requestSubmit()`.  It's less than ideal, but is fairly concise at least.  The `requestSubmit` function is something that Turbo is listening for, and so by invoking that, we're invoking all the stuff that Turbo does for us related to submitting the form.  It does **NOT** however turn our submit button disabled, nor will it disable any other inputs.  However, it is doing enough for us to help out, because when that function is invoked, the `aria-busy="true"` attribute will be placed into our form, and we can key off of this in our CSS to produce the same effect.  That's a massive savings, I otherwise was going to need to pull `Stimulus` into this demo which would have been quite distracting.  


## Step 4: Setup the Update Status Controller Method and Routing

So in order to get this to work, we need to expand our post resource to include an `:update_checked` action.  

(config/routes.rb)
```ruby
Rails.application.routes.draw do
  resources :posts

  resources :posts, only: [] do
    member do
      patch :update_checked
    end
  end
  .
  .
  .
```

(app/controllers/posts_controller.rb)
```ruby
def update_checked
  @post = Post.find(params[:id])
  @post.update(published: post_params[:published] == "1")

  respond_to do |format|
    # Simple (better) way
    # format.turbo_stream { render turbo_stream: turbo_stream.update(@post) }

    # Targeted to only update the individual checkbox form instead of the entire _post.html.erb partial
    # But the whole partial still has to go over the wire so it's not any more bandwidth efficient unless
    # you break out the checkbox into it's own partial
    format.turbo_stream { render turbo_stream:
                            turbo_stream.update(:post,
                                              partial: "posts/post",
                                              target: "post_#{@post.id}_published",
                                              locals: { post: @post }) }

    format.html { redirect_to posts_path, notice: "Post updated successfully" }
    format.json { render json: { success: true, published: @post.published } }
  end
end
```

Here we're using `format.turbo_stream` as our responder.  Anytime we submit a form using turbo_stream, Turbo adds a content-type header to the payload which our rails app can use in determining which responder format to use.  

I wrote a long-form turbo_stream responder.  It doesn't need to be so verbose, you could switch to the concise syntax instead.

```ruby
format.turbo_stream { render turbo_stream: turbo_stream.update(@post) }
```

However, I wanted to update just the single HTML element with the matching id, so I added that parameter `target: "post_#{@post.id}_published"`.  

As an exercise to the reader, you may enjoy refactoring the checkbox into it's own partial.  This would make the component more reusable, and actually cut down on bandwidth going over the wire.  I don't recommend wasting time doing this every time you implement reactive inputs, but it may prove valuable to have this as a reference for when you've attracted too many users to your app.  


## Reference
- [best documentation on turbo, imho](https://www.hotrails.dev/turbo-rails/turbo-frames-and-turbo-streams)
- [Streaming from HTTP Responses](https://turbo.hotwired.dev/handbook/streams#streaming-from-http-responses)
- [On Submit Behavior](https://github.com/hotwired/turbo/pull/386)

