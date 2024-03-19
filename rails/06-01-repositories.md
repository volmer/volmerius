---
tags:
  - rails
  - the-missing-pieces
layout: rails-page
title: Repositories
date: 2021-02-01
---

A big subset of smells in Rails apps is found in Active Record classes. As seen
previously, these objects just do way too much by default and are abused to
operate both persistence and business logic roles. One of the goals of a
sustainable Rails architecture is to isolate Active Record down to its basic
database-related capabilities, and to keep the app’s core business logic as
decoupled as possible from it. To this end, a number of objects will be
introduced on top of the persistence layer, starting with Repositories.

Repositories are responsible for the persistence layer of the app. They
encapsulate Rails’ Active Record in a subset of simple methods for querying and
persistence of data, and return simple read-only objects as a result. This
allows the app to isolate Active Record only to this subset, exposing only the
desired queries and methods to other layers through Repositories. Let’s refactor
the previous example of the Blog app to encapsulate the Article Record behind a
Repository.

As mentioned previously, Active Record objects are now referred to as simply
Records. The previous Article class is now moved from `app/models` to
`app/records` and renamed to Article Record.

```ruby
# app/records/article_record.rb

class ArticleRecord < ApplicationRecord
  self.table_name = 'articles'

  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }
end
```

All operations previously handled by Article Record, such as finding, creating,
and deleting records are now done through the Article Repository.

```ruby
# app/repositories/articles_repository.rb

class ArticleRepository
  def all
    ArticleRecord.all
  end

  def create(title:, body:)
    ArticleRecord.create!(title: title, body: body)
  end

  def find(id)
    ArticleRecord.find(id)
  end

  def update(id, title:, body:)
    record = find(id)
    record.update!(title: title, body: body)
    record
  end

  def delete(id)
    record = find(id)
    record.destroy!
  end
end
```

```ruby
# app/controllers/articles_controller.rb

class ArticlesController < ApplicationController
  # GET /articles
  def index
    @articles = ArticleRepository.new.all
  end

  # GET /articles/1
  def show
    @article = ArticleRepository.new.find(params[:id])
  end

  # GET /articles/new
  def new
    @article = ArticleRecord.new
  end

  # GET /articles/1/edit
  def edit
    @article = ArticleRepository.new.find(params[:id])
  end

  # POST /articles
  def create
    @article = ArticleRepository.new.create(
      title: article_params[:title], body: article_params[:body]
    )

    redirect_to article_path(@article), notice: 'Article was successfully created.'
  rescue ActiveRecord::RecordInvalid => error
    @article = error.record
    render :new
  end

  # PATCH/PUT /articles/1
  def update
    @article = ArticleRepository.new.update(
      params[:id], title: article_params[:title], body: article_params[:body]
    )

    redirect_to article_path(@article), notice: 'Article was successfully updated.'
  rescue ActiveRecord::RecordInvalid => error
    @article = error.record
    render :edit
  end

  # DELETE /articles/1
  def destroy
    ArticleRepository.new.delete(params[:id])
    redirect_to articles_url, notice: 'Article was successfully destroyed.'
  end

  private


  # Only allow a list of trusted parameters through.
  def article_params
    params.require(:article_record).permit(:title, :body)
  end
end
```

Note, however, that Active Record is not completely encapsulated just yet. After
all, queries still return Record objects that controllers and views rely
on in order to handle parameters and read data. These Records are used for
multiple responsibilities: in some actions, such as new and edit, they represent
the user’s input; in others, like in index and show, they play the role of
actual persisted entities of the system. Records also hold the validation errors
that might happen when a persistence operation is attempted.

In order to isolate Active Record completely, we must replace these cases with
simpler objects for each of these responsibilities. Enter Inputs and Models.
