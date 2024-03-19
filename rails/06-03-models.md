---
tags:
  - rails
  - the-missing-pieces
layout: rails-page
title: Models
date: 2021-02-01
---

Models are objects that represent core entities of the app’s business logic.
These are usually persisted and can be fetched and created as needed. They have
unique keys for identification (usually a numeric value), and, most importantly
perhaps, they are immutable. This is the key difference between this new Model
layer of objects and the Active Record instances regularly referred to as models
in typical Rails default apps.

Another difference between Models and Records is that, once instantiated, Models
simply hold its attributes immutably, and they don’t have any capabilities to
create or update any information in the persistence layer.

The collaboration between Repositories and Models is what allows Active Record
to be completely hidden away from any other areas of the app. There are no
references to Records in controllers, views, and anywhere else. Repositories are
invoked instead, which in turn return read-only Models.

Let’s refactor the previous example of the Blog app to encapsulate the Article
Record behind a Model and use those as return values in the Article Repository.

```ruby
# app/models/article.rb

class Article
  attr_reader :id, :title, :body, :created_at, :updated_at

  def initialize(id:, title:, body:, created_at:, updated_at:)
    @id = id
    @title = title
    @body = body
    @created_at = created_at
    @updated_at = updated_at
  end
end
```

```ruby
class ArticleRepository
  def all
    ArticleRecord.all.map { |record| to_model(record.attributes) }
  end

  def create(input)
    record = ArticleRecord.create!(title: input.title, body: input.body)
    to_model(record.attributes)
  end

  def find(id)
    record = ArticleRecord.find(id)
    to_model(record.attributes)
  end

  def update(id, input)
    record = ArticleRecord.find(id)
    record.update!(title: input.title, body: input.body)
    to_model(record.attributes)
  end

  def delete(id)
    record = ArticleRecord.find(id)
    record.destroy!
  end

  private

  def to_model(attributes)
    Article.new(**attributes.symbolize_keys)
  end
end
```

Note that since we were already using the Article Record as read-only objects,
we were able to simply change the value returned by the Repository to a Model
without breaking our controller and views.
