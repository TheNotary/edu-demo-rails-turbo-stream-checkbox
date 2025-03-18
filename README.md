# Rails - Trubo Stream Checkboxes

**Turbo Streams** is a neat technology incorporated into the vanilla Rails stack to enable the rapid development of single page applications that feel alive and responsive. The idea is to use websockets to transmit updates to the browser.  There are lots of frameworks out there that can do this, but rails is the only one I'm aware of that defines these reactive application behaviors via markup language rather than attempting to define the behavior using overly complicated procedural logic.

This repository intends to demonstrate the creation of a database-backed checkbox that toggles an entry in the database live when the user interacts with it, and changes it's state after the backend register's the user's input.


## Generator Commands Used

```
r new edu-demo-rails-turbo-streams-checkbox
cd edu-demo-rails-turbo-streams-checkbox
alias r="bin/rails"

# Setup the database and scaffold out the views
r g scaffold Posts title:string body:text published:boolean
r db:migrate

# This just uncomments the last line in config/routes.rb
sed -i 's/# \(root "posts#index"\)/\1/' config/routes.rb
```


## Reference
- [Streaming from HTTP Responses](https://turbo.hotwired.dev/handbook/streams#streaming-from-http-responses)

format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
