class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]

  # GET /posts or /posts.json
  def index
    @posts = Post.all
  end

  # GET /posts/1 or /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  def update_checked
    @post = Post.find(params[:id])
    @post.update(published: post_params[:published] == "1")
    # binding.pry

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

  # POST /posts or /posts.json
  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: "Post was successfully updated." }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to posts_path, status: :see_other, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.expect(post: [ :title, :body, :published ])
    end
end
